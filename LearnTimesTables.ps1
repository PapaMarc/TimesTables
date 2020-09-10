# inspired by, and built upon
# https://www.reddit.com/r/PowerShell/comments/ikoy4c/how_i_got_my_6_year_old_to_practice_the_alphabet/
# by u/_lahell_  https://www.reddit.com/user/_lahell_/
#
# as i needed an excuse to get my slightly older kiddo to a) practice her times tables, and b) start to code
# So now she needs to fire up VSCode and powershell for 10min a day... 
#
# (also added some suggestions from https://www.reddit.com/user/KyleKowalski/ to spice up the kudos messages a bit)

Add-Type -AssemblyName System.Speech
$Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
$Speech.Speak("Do  you want to play a game? Enter times table to practice, or hit enter for all tables up to 12")
[Int]$InitTable = Read-Host -Prompt ("Enter times table to practice, or hit enter for all tables up to 12")
$Table = $InitTable

while($true) {
    If ($InitTable -eq 0) {
    [Int]$Table = (Get-Random -Minimum 1 -Maximum 12)
    }
        [Int]$Factor = (Get-Random -Minimum 1 -Maximum 12)
        [Int]$Product =  $Table * $Factor
        $Assignment = "$Table x $Factor"
        $Speech.Speak("$Table times ;$Factor equals")
        $Answer = Read-Host -Prompt $Assignment
        if ($Answer.Length -gt 0) {
            if ($Product -eq $Answer) {
                Write-host "Correct" -ForegroundColor "Green"
                Write-host "---"
                $Speech.Speak("Correct! You entered $Answer. $Table times $Factor equals $Product.")
            }
    # '^\d+$' == regex for 'only numbers'
           elseif ($Answer -NotMatch '^\d+$') {
               Write-Host "The correct answer is $Product"
               Write-host "---"
               $Speech.Speak("That was not a number. The correct answer is $Product.")
           } 
            elseif ($Product -ne $Answer) {
                Write-host "Incorrect" -ForegroundColor "Red"
                Write-host "The correct answer is $Product"
                Write-host "---"
                $Speech.Speak("Incorrect. You should have entered ;$Product, but you entered ;$Answer. $Table times $Factor equals $Product.")
            }
        } else {
            $Speech.Speak("You did not provide an answer.")
        }
}