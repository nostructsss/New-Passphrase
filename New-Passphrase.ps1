function New-Passphrase
{
    <#
    .SYNOPSIS
        Generates a secure, multi-word passphrase from a local dictionary file.

    .DESCRIPTION
        The New-Passphrase function creates a cryptographically randomized passphrase using words 
        sourced from a local file located at $HOME\Documents\words_alpha.txt. It allows full 
        customization over word count, character lengths, and custom string delimiters. 
        Upon completion, the passphrase is printed to the host and automatically copied to the system clipboard.

    .PARAMETER NumberOfWords
        The exact number of words to pull from the dictionary file to construct the passphrase. Minimum value is 1.

    .PARAMETER Delimiter
        A custom character or string used to separate each word in the passphrase. If omitted, a standard space (" ") is used.

    .PARAMETER MinLength
        The minimum allowed total character length of the generated passphrase. Default is 1.

    .PARAMETER MaxLength
        The maximum allowed total character length of the generated passphrase. Must be greater than or equal to the MinLength parameter.

    .EXAMPLE
        New-Passphrase -NumberOfWords 4
        
        Generates a 4-word passphrase separated by spaces and copies it to the clipboard.

    .EXAMPLE
        New-Passphrase -NumberOfWords 5 -Delimiter "-" -MinLength 20 -MaxLength 40 -Verbose
        
        Generates a passphrase with exactly 5 words, separated by hyphens. It forces the output string to be 
        between 20 and 40 characters long while outputting real-time verbose execution logs.

    .INPUTS
        None. You cannot pipe objects into this function.

    .OUTPUTS
        System.String. Outputs a passphrase string to the host display and system clipboard.

    .NOTES
        Author: Jason Okafor
        Prerequisites: Requires a valid text file containing words line-by-line located at "$HOME\Documents\words_alpha.txt".
    #>

    [CmdletBinding(
    SupportsShouldProcess=$true)]
    
    param
    (
        [Parameter(
        Mandatory=$true, HelpMessage="Enter the number of words for the Passphrase (Minimum 1):")]
        [ValidateRange(1, [int16]::MaxValue)]
        [Int16]$NumberOfWords,

        [Parameter(
        Mandatory=$false, HelpMessage="Enter a delimiter for your passphrase:")]
        [String]$Delimiter,

        [Parameter(
        Mandatory=$false, HelpMessage="Enter the minimum Passphrase length:")]
        [ValidateRange(1, [int16]::MaxValue)]
        [Int16]$MinLength = 1,
        
        [Parameter(
        Mandatory=$false, HelpMessage="Enter the maximum Passphrase length:")]
        [ValidateScript(
        {
            if ($_ -lt $PSBoundParameters['MinLength']) 
            {
                throw "MaxLength ($_ ) cannot be less than MinLength ($($PSBoundParameters['MinLength']))."
            }
            
            $true
        }
        )
        ]
        [ValidateRange(1, [int16]::MaxValue)]
        [Int16]$MaxLength = [int16]::MaxValue
    )

    process
    {
        $File = "$HOME\Documents\words_alpha.txt"
        if (!(Test-Path $File))
        {
            Throw [System.IO.FileNotFoundException]"Word list file not found at $File"
        }

        Write-Verbose "Generating Passphrase..."
        
        $WordList = Get-Content $File

        do 
        {            
            for($j=0; $j -lt 100; $j++)
            {
                Write-Progress "Generating Passphrase %:" -PercentComplete $j
            }

            if ($null -ne (Get-Command Get-SecureRandom -ErrorAction SilentlyContinue))
            {
                $PassphraseElements = $WordList | Get-SecureRandom -Count $NumberOfWords
            }
            else
            {
                #PS 5.1 implementation for true randomness
                $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
                $PassphraseElements = @()
                
                for ($i = 0; $i -lt $NumberOfWords; $i++)
                {
                    $bytes = [byte[]]::new(4)
                    $rng.GetBytes($bytes)
                    $randInt = [BitConverter]::ToInt32($bytes, 0)
                    
                    $index = [Math]::Abs($randInt) % $WordList.Count
                    $PassphraseElements += $WordList[$index]
                }
                $rng.Dispose()
            }
            
            $Separator = if ($null -ne $Delimiter) { $Delimiter } else { " " }
            $TestPassphrase = $PassphraseElements -join $Separator

        } 
        while (($TestPassphrase.Length -lt $MinLength) -or ($TestPassphrase.Length -gt $MaxLength))

        
        Write-Verbose "Passphrase Length: $($TestPassphrase.Length)"
        Write-Host "Passphrase: $TestPassphrase"
        Write-Verbose "Passphrase Generated"

        Set-Clipboard $TestPassphrase
    }
}