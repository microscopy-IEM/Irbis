import argparse
import json
import statistics
import time
from pathlib import Path

import numpy as np
import trimesh


SCRIPT_NAME = "mesh_subtract_and_separate_and_save_plane_trimesh_py_script.py"


def load_target_function(script_path: Path):
    """Load mesh_subtract_and_separate without executing MATLAB call block."""
    source = script_path.read_text(encoding="utf-8")
    marker = "# Call from Matlab"
    cut = source.find(marker)
    if cut != -1:
        source = source[:cut]

    namespace = {}
    exec(compile(source, str(script_path), "exec"), namespace)

    if "mesh_subtract_and_separate" not in namespace:
        raise RuntimeError("mesh_subtract_and_separate function was not found in target script")

    return namespace["mesh_subtract_and_separate"]


def mesh_to_data(mesh: trimesh.Trimesh):
    return {
        "vertices": np.asarray(mesh.vertices, dtype=np.float64),
        "faces": np.asarray(mesh.faces, dtype=np.int32),
    }


def make_cases(seed: int):
    rng = np.random.default_rng(seed)

    cases = []

    # Case 1: sphere minus offset sphere
    big1 = trimesh.creation.icosphere(subdivisions=3, radius=1.2)
    small1 = trimesh.creation.icosphere(subdivisions=2, radius=0.55)
    t1 = np.eye(4)
    t1[:3, 3] = [0.55, 0.1, 0.0]
    small1.apply_transform(t1)
    cases.append(("sphere_minus_sphere", big1, small1))

    # Case 2: box minus tilted cylinder
    big2 = trimesh.creation.box(extents=[2.2, 1.8, 1.6])
    small2 = trimesh.creation.cylinder(radius=0.28, height=2.4, sections=48)
    rot2 = trimesh.transformations.euler_matrix(np.deg2rad(20), np.deg2rad(35), np.deg2rad(5))
    rot2[:3, 3] = [0.35, 0.15, 0.05]
    small2.apply_transform(rot2)
    cases.append(("box_minus_tilted_cylinder", big2, small2))

    # Case 3: cylinder minus sphere
    big3 = trimesh.creation.cylinder(radius=0.95, height=2.5, sections=64)
    small3 = trimesh.creation.icosphere(subdivisions=2, radius=0.6)
    t3 = np.eye(4)
    t3[:3, 3] = [0.25, -0.2, 0.2]
    small3.apply_transform(t3)
    cases.append(("cylinder_minus_sphere", big3, small3))

    # Randomized translation jitter for slight variability
    jitter = rng.normal(scale=0.03, size=(len(cases), 3))
    jittered = []
    for i, (name, big, small) in enumerate(cases):
        tt = np.eye(4)
        tt[:3, 3] = jitter[i]
        small_copy = small.copy()
        small_copy.apply_transform(tt)
        jittered.append((name, big, small_copy))

    return jittered


def to_unit(v):
    n = np.linalg.norm(v)
    if n <= 1e-12:
        return None
    return v / n


def evaluate_quality(output, mesh2, distance_threshold):
    component_data = output.get("component_data", {})
    base_points = np.asarray(output.get("base_points", np.zeros((0, 6))), dtype=np.float64)

    mesh2_query = trimesh.proximity.ProximityQuery(mesh2)

    records = []
    for i, base in enumerate(base_points, start=1):
        comp = component_data.get(i)
        if comp is None:
            continue

        comp_mesh = trimesh.Trimesh(
            vertices=np.asarray(comp["vertices"], dtype=np.float64),
            faces=np.asarray(comp["faces"], dtype=np.int32),
            process=False,
        )

        scale = float(np.linalg.norm(comp_mesh.bounds[1] - comp_mesh.bounds[0]))
        if scale <= 1e-12:
            scale = 1.0

        p = base[:3]
        n = base[3:6]

        valid_point = np.all(np.isfinite(p))
        valid_normal = np.all(np.isfinite(n))

        if valid_point:
            _, surf_d, tri_ids = trimesh.proximity.closest_point(comp_mesh, p.reshape(1, 3))
            surface_dist = float(surf_d[0])
            _, cap_d, _ = mesh2_query.on_surface(p.reshape(1, 3))
            cap_dist = float(cap_d[0])
        else:
            surface_dist = np.inf
            cap_dist = np.inf
            tri_ids = []

        normal_norm = float(np.linalg.norm(n)) if valid_normal else np.nan
        inward_dot = np.nan
        local_align = np.nan

        if valid_point and valid_normal and len(tri_ids) > 0 and 0 <= int(tri_ids[0]) < len(comp_mesh.face_normals):
            n_u = to_unit(n)
            f_u = to_unit(comp_mesh.face_normals[int(tri_ids[0])])
            if n_u is not None and f_u is not None:
                local_align = float(np.dot(n_u, f_u))
                inward_vec = comp_mesh.centroid - p
                inward_u = to_unit(inward_vec)
                if inward_u is not None:
                    inward_dot = float(np.dot(n_u, inward_u))

        surface_pass = surface_dist < 1e-3 * scale
        cap_pass = cap_dist < 1.25 * distance_threshold
        normal_pass = np.isfinite(normal_norm) and 0.5 <= normal_norm <= 1.5
        inward_pass = np.isfinite(inward_dot) and inward_dot > 0.0

        records.append(
            {
                "component_id": i,
                "surface_dist": surface_dist,
                "cap_dist": cap_dist,
                "normal_norm": normal_norm,
                "local_align": local_align,
                "inward_dot": inward_dot,
                "surface_pass": bool(surface_pass),
                "cap_pass": bool(cap_pass),
                "normal_pass": bool(normal_pass),
                "inward_pass": bool(inward_pass),
                "overall_pass": bool(surface_pass and cap_pass and normal_pass and inward_pass),
            }
        )

    return records


def run_benchmark(func, cases, iterations, distance_threshold):
    case_results = []

    for name, big_mesh, small_mesh in cases:
        times = []
        quality_all = []
        errors = []

        mesh_data = [mesh_to_data(big_mesh), mesh_to_data(small_mesh)]

        for _ in range(iterations):
            t0 = time.perf_counter()
            try:
                output = func(mesh_data=mesh_data, green_threshold=0.3, distance_threshold=distance_threshold)
                elapsed = time.perf_counter() - t0
                times.append(elapsed)
                quality_all.extend(evaluate_quality(output, small_mesh, distance_threshold))
            except Exception as exc:
                elapsed = time.perf_counter() - t0
                times.append(elapsed)
                errors.append(str(exc))

        result = {
            "case": name,
            "iterations": iterations,
            "time_mean_s": statistics.mean(times) if times else np.nan,
            "time_std_s": statistics.pstdev(times) if len(times) > 1 else 0.0,
            "time_min_s": min(times) if times else np.nan,
            "time_max_s": max(times) if times else np.nan,
            "n_quality_records": len(quality_all),
            "n_overall_pass": int(sum(1 for r in quality_all if r["overall_pass"])),
            "n_fail": int(sum(1 for r in quality_all if not r["overall_pass"])),
            "errors": errors,
            "quality": quality_all,
        }
        case_results.append(result)

    return case_results


def print_summary(results):
    print("\n=== Performance + Quality Summary ===")
    for r in results:
        print(
            f"- {r['case']}: mean={r['time_mean_s']:.4f}s std={r['time_std_s']:.4f}s "
            f"min={r['time_min_s']:.4f}s max={r['time_max_s']:.4f}s "
            f"quality_pass={r['n_overall_pass']}/{r['n_quality_records']} errors={len(r['errors'])}"
        )


def main():
    parser = argparse.ArgumentParser(description="Benchmark and quality-check mesh_subtract_and_separate")
    parser.add_argument("--script", default=SCRIPT_NAME, help="Path to target script")
    parser.add_argument("--iterations", type=int, default=3, help="Iterations per synthetic case")
    parser.add_argument("--distance-threshold", type=float, default=0.1, help="Distance threshold passed to target function")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for case jitter")
    parser.add_argument("--report", default="", help="Optional output JSON report path")
    args = parser.parse_args()

    script_path = Path(args.script).resolve()
    if not script_path.exists():
        raise FileNotFoundError(f"Script not found: {script_path}")

    func = load_target_function(script_path)
    cases = make_cases(args.seed)
    results = run_benchmark(func, cases, args.iterations, args.distance_threshold)
    print_summary(results)

    if args.report:
        report_path = Path(args.report).resolve()
        report_path.write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(f"\nReport written to: {report_path}")


if __name__ == "__main__":
    main()
