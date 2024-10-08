function Publish-Addon {
    param (
        [ValidateSet("Retail", "Classic", "Wrath", "Vanilla", "All")]
        [string[]]$Flavor = "Retail",
        [ValidateSet("Live", "PTR", "Beta", "Alpha", "All")]
        [string[]]$Channel = "Live",
        [string]$PackagerVersion = "v2.3.1",
        [string]$PackagerSha256 = "40c28ec61b19ce6cba7051580d14e6ee6e8c8a42a364396788cc4876e55ceaec",
        [switch]$SkipTocCreation = $false,
        [switch]$live = $false,
        [switch]$ptr = $false,
        [switch]$beta = $false,
        [switch]$alpha = $false
    )
    process {
        if (!(Test-Path .\*.pkgmeta*)) {
            Write-Host "The current directory does not contain a pkgmeta file"
            return
        }

        $WOW_HOME = $env:WOW_HOME
        if (!(Test-Path $WOW_HOME)) {
            Write-Host "The WOW_HOME environment variable hasn't been set. Please set it to the location of World of Warcraft Launcher.exe"
            return;
        }

        if ($live -or $ptr -or $beta -or $alpha) {
            $Channel = @()

            if ($live) {
                $Channel += "Live"
            }

            if ($ptr) {
                $Channel += "PTR"
            }

            if ($beta) {
                $Channel += "Beta"
            }

            if ($alpha) {
                $Channel += "Alpha"
            }
        }

        # Figure out what game flavors we're publishing for
        $retail = $Flavor -Contains "Retail" -or $Flavor -Contains "All"
        $wrath = $Flavor -Contains "Wrath" -or $Flavor -Contains "Classic" -or $Flavor -Contains "All"
        $vanilla = $Flavor -Contains "Vanilla" -or $Flavor -Contains "Classic" -or $Flavor -Contains "All"

        # Figure out what release channels we're publishing for
        $live = $Channel -Contains "Live" -or $Channel -Contains "All"
        $ptr = $Channel -Contains "PTR" -or $Channel -Contains "All"
        $beta = $Channel -Contains "Beta" -or $Channel -Contains "All"
        $alpha = $Channel -Contains "Alpha" -or $Channel -Contains "All"

        # Grab all of the game directory folders we're going to publish to
        $gameDirs = [System.Collections.Generic.List[string]]::new()
        if ($retail) {
            if ($live) {
                $gameDirs.Add("_retail_")
            }

            if ($ptr) {
                $gameDirs.Add("_ptr_")
                $gameDirs.Add("_xptr_")
            }

            if ($beta) {
                $gameDirs.Add("_beta_")
            }

            if ($alpha) {
                $gameDirs.Add("_alpha_")
            }
        }

        if ($wrath) {
            if ($live) {
                $gameDirs.Add("_classic_")
            }

            if ($ptr) {
                $gameDirs.Add("_classic_ptr_")
            }

            if ($beta) {
                $gameDirs.Add("_classic_beta_")
            }

            if ($alpha) {
                $gameDirs.Add("_classic_alpha_")
            }
        }

        if ($vanilla) {
            if ($live) {
                $gameDirs.Add("_classic_era_")
            }

            if ($ptr) {
                $gameDirs.Add("_classic_era_ptr_")
            }

            if ($beta) {
                $gameDirs.Add("_classic_era_beta_")
            }

            if ($alpha) {
                $gameDirs.Add("_classic_era_alpha_")
            }
        }

        $WORKING_DIR = "/tmp/.publish-addon"
        $addonDir = "$WORKING_DIR/in"
        $releaseDir = "$WORKING_DIR/out"
        $packager = "$WORKING_DIR/release.sh"

        # 1. Set up directories
        wsl -e mkdir -p "$addonDir"

        # 2. Copy files over to WSL (to avoid performance issues when working via NTFS)
        Write-Host "Copying files from $pwd"
        $pwdWSL = wsl -e wslpath "$pwd"
        wsl -e rsync -rz --delete "$pwdWSL/" "$addonDir"

        # 3. Grab the packager script and verify its hash
        wsl -e curl -s -o "$packager" "https://raw.githubusercontent.com/BigWigsMods/packager/$PackagerVersion/release.sh"

        wsl echo "$PackagerSha256 $packager" `| sha256sum -c | Out-Null

        if (-not $?) {
            throw 'Failed to verify hash for release.sh'
        }

        wsl -e chmod u+x "$packager"

        # 4. Construct the packager arguments
        $packagerArgs = [System.Collections.Generic.List[string]]::new()
        $packagerArgs.Add('-dlz')
        $packagerArgs.Add('-t {0}' -f $addonDir)
        $packagerArgs.Add('-r {0}' -f $releaseDir)

        if (-not $SkipTocCreation) {
            $packagerArgs.Add('-S')
        }

        # 5. Execute the packager
        Write-Host "Running packager"
        Invoke-Expression "wsl -e $packager $($packagerArgs -Join ' ')"

        # 6. Copy the output files over to the target WoW directories
        $releaseDirUNC = wsl -e wslpath -w $releaseDir
        foreach ($gameDir in $gameDirs) {
            $wowAddonsDir = Join-Path $WOW_HOME $gameDir Interface AddOns

            if (Test-Path -Path $wowAddonsDir) {
                $wowAddonsDirWSL = wsl -e wslpath "$wowAddonsDir"

                Write-Host "Copying files to $wowAddonsDir"
                Get-ChildItem -Directory $releaseDirUNC | ForEach-Object {
                    $src = $_.FullName
                    $srcWSL = wsl -e wslpath "$src"
                    wsl -e rsync -r --delete "$srcWSL" "$wowAddonsDirWSL"
                }
            }
        }

        # 7. Cleanup
        Write-Host "Cleaning up"
        wsl -e rm -rf $WORKING_DIR
        Write-Host "Publish complete"
    }
}

Export-ModuleMember Publish-Addon
