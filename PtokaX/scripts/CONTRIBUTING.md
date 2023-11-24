# <a name="contrib"></a>Contribute
The HiT Hi FiT Hai DC++ hub scripts is the result of efforts from various [contributors][1]. While we admire new users wishing to contribute to the scripts, here follows a few guidelines that we need contributors to follow in order to keep a sustainable development of the project.

# <a name="start"></a>Getting started
Make sure that you have a GitHub account.

## <a name="fork"></a>Forking, cloning and remote management
Before you begin making any changes to the scripts, please fork the GitHub repository to your own GitHub profile. Clone your own fork to the system at an appropriate location. Afterwards, add our own repository as a new remote:

    git clone https://github.com/<nick>/ptokax-scripts.git
    cd ptokax-scripts
    git remote add hhfh https://github.com/HiT-Hi-FiT-Hai/ptokax-scripts.git
The new remote is helpful so that you can [keep up-to-date][2] with any changes to the repo since you last updated it.

## <a name="up2date"></a>Keeping up-to-date
To get to the current stage of development in your own repository:

    git checkout master
    git pull hhfh master
    git push origin master

## <a name="modifying"></a>Modifying the scripts
Before you actually start making changes to the scripts, make sure that you are working in a new branch (not **`master`**). If you are working on a fix for one of the [open issues][3]; it'd be preferred to name your new branch as `issues/<number>`.

    git checkout -b issues/25

## <a name="commit"></a>Committing etiquettes
When you're committing the changes to your branch, make sure that the commits follow a simple style structure:

    The commit title is a maximum of 72 characters

    The line following the title is left blank. Afterwards,
    the commit description follows with each line not more
    than 80 characters in length. You can use markdown list
    formatting to log the changes made during the commit.

    Any new paragraph in the commit message should also
    be separated by exactly one blank line.

## <a name="pull"></a>Opening a pull request
After you've made your changes to the scripts and pushed the content to your own GitHub repository; you still need to notify the maintenance staff of HiT Hi FiT Hai about these changes so that they can be incorporated into the hub as well. This is what a pull request is for. Using GitHub's easy-to-use interface, send us a [pull request][4].

## <a name="surety"></a>Wait till PR is merged
After you've sent us a pull request, wait until the pull request is merged into the repository. There may also be a possibility that the staff suggests to make some alterations or improvements on your work. Once the staff has decided that your branch is ready to be merged into the main project, they will act accordingly.

Once your pull request has been merged, you can [update][2] your own repository.


  [1]: https://github.com/HiT-Hi-FiT-Hai/ptokax-scripts/graphs/contributors
  [2]: #up2date
  [3]: https://github.com/HiT-Hi-FiT-Hai/hhfh-issues/issues
  [4]: https://github.com/HiT-Hi-FiT-Hai/ptokax-scripts/pulls
