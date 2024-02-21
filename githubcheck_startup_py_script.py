import subprocess
from plyer import notification
import random
import datetime

"""This is a function called upon Matlab startup. It checks for github changes."""
"""Do not read the code, unless you want to spoil all the fun ;)."""

def check_for_uncommitted_changes(repo_path):
    """Check for uncommitted changes in the given repository path."""
    try:
        now = datetime.datetime.now()
        if now.hour >= 7 and now.hour < 10 and (0 <= now.weekday() <= 4):
            timespec = [
                'Also, did you remeber to mark your arrival to work?;)',
                'Have fun!',
                'Also, how are you doing today?:)',
                'Good morning:)',
                ''
            ]
        elif now.hour >= 10 and now.hour < 15:
            timespec = [
                'Also, good to see you here:)',
                'I hope your day is doing good so far.'
            ]
        elif now.hour >= 23 or now.hour < 4:
            timespec = [
                'But maybe...should\'t you go to sleep instead?',
                'Also, shouldn\'t you go to sleep;)?',
                'Also, what are you still doing here?',
                '',
                ''
            ]
        else:
            timespec = ''
        subprocess.call(["git", "-C", repo_path, "fetch"])
        status_output = subprocess.check_output(["git", "-C", repo_path, "status"], universal_newlines=True)
        if 'Your branch is up to date' not in status_output and 'nothing to commit' not in status_output:
            variations = [
                'Remember to pull changes from GitHub!',
                'Your local repository differs from GitHub. Remember to pull the changes first.',
                'This is your friendly reminder that you need to pull the changes;)',
                'There is something new on GitHub. Give it a look.'
            ]
        elif 'Your branch is behind' in status_output:
            variations = [
                'There are new changes in the remote repository. Consider pulling them.',
                'Your local repository is lagging behind GitHub. Remember to pull the changes before you start working.',
                'Remember to pull changes from GitHub!',
                'Your local repository differs from GitHub. Remember to pull the changes first.',
                'This is your friendly reminder that you need to pull the changes;).',
                'There is something new on GitHub. Give it a look.'
            ]
        else:
            variations = [
                'Your repository is up to date. Feel free to start working.',
                'Nothing new on GitHub, you can start working (but don\'t overdo it;)).',
                'Your version and the one on GitHub are the same.',
                'You\'re ready to go!'
            ]
        disp_message = f'{random.choice(variations)} {random.choice(timespec)}'
        notification.notify(
            title='Your talking unicorn here',
            message=disp_message,
            app_name='Talking unicorn'
        )
        return(disp_message)
    except Exception as e:
        disp_message = f'An error occurred: {e}'
        notification.notify(
            title='Oops, an error -_o_-',
            message=disp_message,
            app_name='Talking unicorn'
        )
        return(disp_message)

# Example repository path, change to your actual repository path
# repo_path = 'C:/Users/sveco/Documents/IEM_microscopy/MMPack'
message = check_for_uncommitted_changes(repo_path)
