# FSLogix start menu rules for RDSH 2019
This script uses the FSLogix Powershell Rules module to assign predefined FSL rules to users and/or groups. The rules templates are based on my blog post on mycugc.org.
You have to install the module from the PSGallery. The script checks whether the PSGallery is a trusted repo. Otherwise you will be asked to trust the repo and install
the module. Put the script in a directory with the rules and run the script in an elevated Powershell session. The FSLogix rules editor must be installed!
Run as admin! If you want to use other groups then Domain Users and Domain Admins, you have to customize the script. The script can be used in several languages, which is important  because the system accounts have different names. In German, the name for the local service is e.g. "LOKALER DIENST".


