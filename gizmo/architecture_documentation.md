# Gizmo architecture

## 1. Introduction and goals
This module gives interactive 3D manipulation tools that can be used to manipulate 3D objects, such as patches.

Main goals:
- Show a 3D gizmo in an axes.
- Let users move, rotate, and scale objects.
- Support both mesh objects and point-based objects.
- Keep preparation logic (`GizmoObjectPreparer`) separate from interaction logic (`GizmoTool`).

---

## 2. Constraints
- MATLAB graphics and callbacks are required.
- The interaction model depends on figure pointer behavior (`iptPointerManager`, `iptSetPointerBehavior`).
- Pixel conversion logic is custom (`MicroMToPixelPosition`) and assumes specific axes/camera setup.

---

## 3. Context and scope
### Business context
- Input: plotted 3D content (patches, scatter/line points, or generated primitives).
- Output: user can interactively place, orient, and scale a gizmo and attached object(s).

### Technical context
Key modules:
- `GizmoTool`: runtime interaction and drawing.
- `GizmoObjectPreparer`: builds the gizmo input struct.
- `createCylinderObject`, `createThinCuboidObject`, `createSphere`: primitive geometry generators.
- `OrbitToolClass`: camera/orbit interaction and callback management.
- `MicroMToPixelPosition`: converts world coordinates to screen pixel coordinates.

---

## 4. Solution strategy
- Use a **prepared gizmo input struct** as the boundary between preparation and interaction.
- Keep geometry generation in small, focused create-functions.
- Keep view/camera logic independent in `OrbitToolClass`.
- Keep world-to-screen conversion centralized in `MicroMToPixelPosition`.

---

## 5. Building block view
### 5.1 `GizmoObjectPreparer`
Purpose:
- Accept input object(s) or predefined shape type.
- Normalize to mesh-like data for analysis.
- Compute center (`gizmoCenter`) if not provided.
- Convert scale axis names to vectors.
- Compute default scale handle positions (outermost points + small outside margin).

Important output fields:
- `objectForGizmo`
- `gizmoCenter`
- `scalePointVectors`
- `scalePointPositions`

### 5.2 `GizmoTool`
Purpose:
- Create gizmo graphics (center, direction handles, rotation rings, optional object and scale points).
- Handle mouse interactions:
  - translate
  - rotate
  - scale
  - snap to sticky points
- Manage callback/pickability lifecycle safely.

### 5.3 Create functions
- `createCylinderObject(...)` -> `[vertices, faces]`
- `createThinCuboidObject(...)` -> `[vertices, faces]`
- `createSphere(...)` -> `[vertices, faces]`

These functions only generate geometry.

### 5.4 `OrbitToolClass`
Purpose:
- Manage orbit, zoom, key/mouse callbacks, active axes selection, and optional timer/debounce logic.
- Provides camera interaction behavior independent of gizmo scaling logic.

### 5.5 `MicroMToPixelPosition`
Purpose:
- Convert 3D world positions (micrometers) to 2D pixel positions.
- Used by gizmo drag math to map cursor motion correctly.

---

## 6. Runtime view (information flow)
### Flow A: Normal object flow
1. User creates/prepares object(s).
2. `GizmoObjectPreparer.build()` returns a gizmo input struct.
3. The gizmo input struct is passed to `GizmoTool(...)`.
4. `GizmoTool` draws gizmo and optional object handles.
5. User drags gizmo controls; callbacks update geometry in real time.

### Flow B: Predefined shape flow
1. User calls `preparePredefined("cylinder" | "thinCuboid" | "sphere")`.
2. Preparer calls the matching create-function.
3. Preparer computes center and scale points.
4. The gizmo input struct is passed to `GizmoTool`.

### Flow C: Sticky-point snapping flow
1. Caller provides `stickyPoints` and `stickyPointNormals`.
2. `GizmoTool.setStickyPoints(...)` enables center snapping.
3. During drag, nearest sticky point is chosen in pixel space.
4. Gizmo center moves there and aligns to the provided normal.

### Flow D: Visual gizmo-size adjustment
1. User hovers an IPT pointer-interactive gizmo handle.
2. User holds `Alt` and scrolls mouse wheel.
3. `GizmoTool` updates an internal visual scale factor and rescales gizmo visuals around gizmo center.
4. Object transformation state is unchanged (this is visual-only resizing of the gizmo).

---

## 7. Detailed gizmo use cases
### Use case A: Move an existing graphical object
When to use:
- The object is already plotted (for example a patch, scatter, or line object).

How it works:
1. User passes existing object handle(s) into `GizmoObjectPreparer.prepare(...)`.
2. Preparer returns `objectForGizmo` with references to those existing objects.
3. `GizmoTool` reuses these handles during interaction.

Lifecycle behavior:
- The original object is **preserved** after gizmo deletion.
- Deleting gizmo removes gizmo visuals/callbacks, not the original object data.

Typical intent:
- Reposition, rotate, or scale a real object already present in the scene.

### Use case B: Use a predefined geometry with gizmo
When to use:
- User wants a quick helper shape (for example cylinder, thin cuboid, sphere).

How it works:
1. User calls `GizmoObjectPreparer.preparePredefined(...)`.
2. Preparer creates geometry (`vertices`, `faces`) through create-functions.
3. `GizmoTool` creates the display object as part of gizmo composition.

Lifecycle behavior:
- The predefined helper object is treated as gizmo-owned visualization.
- When gizmo is deleted, this helper object is **deleted too**.

Typical intent:
- Use a temporary reference shape to place/align/measure interaction in 3D.

### Use case C: Pose-only gizmo (no object)
When to use:
- User needs only position/orientation, without attaching any visible object.

How it works:
1. User constructs `GizmoTool` with no object input.
2. User manipulates gizmo directly to select center and direction.
3. User reads pose using:
  - `getCentrePositionUM()`
  - `getRotationVector()`

Optional guidance:
- User can provide sticky points and normals via `setStickyPoints(...)`.
- Center snaps to nearest sticky point and orientation aligns to its normal.

Typical intent:
- Find candidate placement/orientation for downstream processing without creating geometry.

---

## 8. Deployment view
Typical runtime setup:
- One MATLAB `figure` or `uifigure`.
- One plotting axes (`axes` or `uiaxes`, with caveats below).
- `OrbitToolClass` attached to figure/axes.
- `GizmoTool` attached to same figure/axes.

---

## 9. Cross-cutting concepts
### Callback safety
- Original callbacks are stored and restored.
- Interactivity is enabled only for active gizmo components.
- Existing plot objects are temporarily made non-pickable while gizmo is active.
- Scroll-wheel behavior is intercepted only for `Alt` + wheel on IPT pointer-interactive gizmo handles; otherwise the original wheel callback is forwarded.

### Coordinate consistency
- Rotation/scaling use local matrices and transformed geometry.
- Pixel conversion is centralized and reused.

### Data contract
- Preparer output is a simple struct so consumers stay decoupled from internals.

---

## 10. Design decisions
- **Separated responsibilities**: preparation (`GizmoObjectPreparer`) vs. interaction (`GizmoTool`).
- **Geometry-only create functions**: keep primitive generation reusable and easy to test.
- **Support object references** in the gizmo input struct (`objectForGizmo`) so existing plotted objects can be reused directly.
- **Object lifecycle policy**: if gizmo uses existing object handles, those objects are preserved after gizmo deletion; if gizmo creates a temporary helper object from geometry, that helper object is deleted with gizmo. This matches the usual need to keep existing scene objects intact.

---

## 11. Quality requirements
- Interactive response should feel immediate during drag.
- Rotations and scaling should stay stable at different camera angles.
- Callback cleanup should avoid leaving figure in a broken interaction state.

---

## 12. Risks and technical debt
- Pixel conversion can be sensitive to axes/layout/camera edge cases.
- Behavior differences between `axes` and `uiaxes` still exist in scripts.
- Some script notes indicate uncertainty when limits are negative.
- Bounding-box origin logic may drift after zooming in some setups.

---

## 13. Prerequisites and practical caveats
From current test scripts and code comments:
- For `MicroMToPixelPosition` conversion to be reliable, set:
  - `ax.Units = "pixels"`
    - Do not use ratio-based units (for example `"normalized"`) for this conversion path.
  - `ax.DataAspectRatio = [1 1 1]`
  - `ax.PlotBoxAspectRatio = [1 1 1]`
  - `ax.NextPlot = 'add'`
- Camera geometry is assumed to be controlled via camera properties (satisfied if `OrbitToolClass.m` is used for rotation management):
  - `CameraPosition`, `CameraTarget`, and `CameraViewAngle` are actively set/maintained by the interaction pipeline.
  - `CameraUpVector` is expected to adjust consistently relative to the other camera properties.
- Be careful when axes limits are negative (explicitly marked as uncertain in scripts).
- `axes` and `uiaxes` can behave differently for this workflow - should be managed in the `MicroMToPixelPosition` conversion
- `MicroMToPixelPosition` conversion is not supported for docked figures.
- For snapping, `stickyPoints` and `stickyPointNormals` must be aligned row-by-row (`N x 3`).
- Visual gizmo scaling is triggered with `Alt` + mouse wheel while pointer is over an IPT pointer-interactive gizmo handle.
- Visual gizmo scaling changes gizmo handle/ring spacing and visual sizes for registered gizmo visuals only.
- Visual gizmo scaling does **not** scale the attached object geometry.
- Scale handles tagged `scalePoint` are excluded from visual gizmo scaling.

---

## Quick API summary
- Build gizmo input struct from existing object(s):
  - `prepared = GizmoObjectPreparer.prepare(object, ...);`
- Build gizmo input struct from predefined shape:
  - `prepared = GizmoObjectPreparer.preparePredefined("sphere");`
- Start gizmo:
  - `gizmo = GizmoTool(ax, fig, prepared.gizmoCenter, [1 0 0], prepared);`
