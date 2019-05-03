#Requires -Modules Pester, PSScriptAnalyzer
<#
.SYNOPSIS
    Tests module for consistency, expected structures, settings, components & files.
.EXAMPLE
    Invoke-Pester
.NOTES
    A generic set of tests to apply to a module
#>

#Get Current Directory
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

#Assume ModuleName from Test File Name
$ModuleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

#Resolve Path to Module Directory
$ModulePath = Resolve-Path "$Here\..\$ModuleName"

#Define Path to Module Manifest
$ManifestPath = Join-Path "$ModulePath" "$ModuleName.psd1"

Get-Module -Name $ModuleName -All | Remove-Module -Force -ErrorAction Ignore
$Module = Import-Module -Name "$ManifestPath" -ArgumentList $true -Force -ErrorAction Stop -PassThru

Describe "Module" {

	Context "Module Consistency Tests" {

		It "has a valid manifest" {

			{$null = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop -WarningAction SilentlyContinue} |
				Should Not Throw

		}

		It "specifies valid root module" {

			$Module.RootModule | Should Be "$ModuleName.psm1"

		}

		It "has a valid description" {

			$Module.Description | Should Not BeNullOrEmpty

		}

		It "has a valid guid" {

			$Module.Guid | Should Be '6c792ac3-4068-4190-a2fc-099d9da50752'

		}

		It "has a valid copyright" {

			$Module.Copyright | Should Not BeNullOrEmpty

		}

		#Get Public Function Names
		$PublicFunctions = Get-ChildItem "$ModulePath\Functions" -Filter *.ps1 -Recurse |
			Select-Object -ExpandProperty BaseName

		Context "Exported Function Analysis" {

			#Get Exported Function Names
			$ExportedFunctions = $Module.ExportedFunctions.Values.name

			It 'exports the expected number of functions' {

				($PublicFunctions | Measure-Object | Select-Object -ExpandProperty Count) |

				Should be ($ExportedFunctions | Measure-Object | Select-Object -ExpandProperty Count)

			}

			$ExportedFunctions.foreach{

				Context "$_" {

					It 'is a public function' {

						$PublicFunctions -contains $_ | Should Be $true

					}

					It 'has a related pester tests file' {
						Test-Path (Join-Path $here "$_.Tests.ps1") | Should Be $true
					}

					Context "Help" {

						$help = Get-Help $_ -Full

						It 'has synopsis' {

							$help.synopsis | Should Not BeNullOrEmpty

						}

						It 'has description' {

							$help.description | Should Not BeNullOrEmpty

						}

						It 'has example code' {

							$help.examples.example.code | Should Not BeNullOrEmpty

						}

						$HelpParameters = $help.parameters.parameter | Where-Object name -NotIn @("WhatIf", "Confirm")

						$HelpParameters.foreach{

							It "has description of parameter $($_.name)" {

								$_.description | Should Not BeNullOrEmpty
							}

						}

					}

				}

			}

		}

	}

	Describe 'PSScriptAnalyzer' {

		$Scripts = Get-ChildItem "$ModulePath" -Filter '*.ps1' -Exclude '*.ps1xml' -Recurse

		$Rules = Get-ScriptAnalyzerRule

		foreach ($Script in $scripts) {

			Context "Checking: $($script.BaseName)" {

				foreach ($rule in $rules) {

					It "passes rule $rule" {

						(Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0

					}

				}

			}

		}

	}

}