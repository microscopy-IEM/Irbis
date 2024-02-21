import subprocess
from plyer import notification
import random
import datetime

"""This is a function called upon Matlab closing. It checks for changes from github."""
"""Do not read the code, unless you want to spoil all the fun ;)."""

def check_for_uncommitted_changes(repo_path):
    """Check for uncommitted changes in the given repository path."""
    try:
        now = datetime.datetime.now()
        if now.hour >= 16 and now.hour < 20 and (0 <= now.weekday() <= 4):
            timespec = [
                'Also, don\'t forget to mark when you leave work;)',
                'Enjoy your evening!',
                ''
            ]
        elif now.hour >= 23 or now.hour < 4:
            timespec = [
                'Also, what are you doing up so late?',
                'Also, shouldn\'t you go to sleep;)?',
                'Good night!',
                '',
                ''
            ]
        else:
            timespec = ''
        subprocess.call(["git", "-C", repo_path, "fetch"])
        status_output = subprocess.check_output(["git", "-C", repo_path, "status"], universal_newlines=True)
        if 'Your branch is up to date' not in status_output and 'nothing to commit' not in status_output:
            variations = [
                'Not so fast, you still haven\'t committed your work.',
                'Do not forget to commit what you did.',
                'Haven\'t you forgotten something?',
                'Remember to commit your work.'
            ]
        elif 'Your branch is behind' in status_output:
            variations = [
                'There are new changes in the remote repository. Consider pulling them.',
                'Your local repository is lagging behind GitHub. Remember to pull the changes before you start working.',
                'GitHub has newer version than your local repository. Why is that?',
                'Your branch is behind...'
            ]
        else:
            variations = [
                'Your repository is up to date. Good job!',
                'I\'m proud of you. You are synced with GitHub.',
                'Good job! Your version and the one on GitHub are the same.',
                'You\'re great! There is no difference between your version and the one on GitHub.'
            ]
        disp_message = f'{random.choice(variations)} {random.choice(timespec)}'
        notification.notify(
            title='Your talking unicorn here',
            message=disp_message,
            app_name='Talking unicorn'
        )
        
        # return(disp_message)
    except Exception as e:
        disp_message = f'An error occurred: {e}'
        notification.notify(
            title='Oops, an error -_o_-',
            message=disp_message,
            app_name='Talking unicorn'
        )
        # return(disp_message)

# Example repository path, change to your actual repository path
# repo_path = 'C:/Users/sveco/Documents/IEM_microscopy/MMPack'
check_for_uncommitted_changes(repo_path)
