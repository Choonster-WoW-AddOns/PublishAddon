# Publish-Addon

This is a PowerShell module written by [Tuller](https://github.com/Tuller) to invoke the [Bigwigs Packager](https://github.com/BigWigsMods/packager) locally when testing addons.

This fork adds some new functionality and backports some functionality from Tuller's new [wowp](https://github.com/Tuller/wowp) script.

## Setup

1. Install [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows)
1. Install [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
1. Import this module into a PowerShell file
1. Set the following environment variables:

   | Name     | Value                                    |
   | -------- | ---------------------------------------- |
   | WOW_HOME | Wherever you installed World of Warcraft |

## Usage

From an AddOn directory with a **.pkgmeta** file, run one of the following:

```powershell
# Publishes an AddOn using the BigWigs Packager tool to the Retail AddOns directory
Publish-Addon

# Publish to one or more release channels (Live, PTR, Beta, Alpha)
Publish-Addon -Channel Live
Publish-Addon -Channel Live, PTR

# All release channels
Publish-Addon -Channel All

# Specify one or more game flavors (Retail, Wrath, Vanilla)
Publish-Addon -Flavor Retail
Publish-Addon -Flavor Wrath, Vanilla

# Classic Era + Classic
Publish-Addon -Flavor Classic

# All game flavors
Publish-Addon -Channel All
```
