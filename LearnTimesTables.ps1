# inspired by, and built upon
# https://www.reddit.com/r/PowerShell/comments/ikoy4c/how_i_got_my_6_year_old_to_practice_the_alphabet/
# by u/_lahell_  https://www.reddit.com/user/_lahell_/
#
# as i needed an excuse to get my slightly older kiddo to a) practice her times tables, and b) start to code
# So now she needs to fire up VSCode and powershell for 10min a day... 
#

# Define AttaKiddo and GetBackUpOnTheHorse Arrays
# used to provide some variation in spoken responses
$Array_AttaKiddo = @("Great Job!","Congrats","Hurrah","Correct","Booyakasha diggity check this out","Boom","Way to go","High Five","Cheers","Woot","Homerun","wicked","superb","Impressive","Awesome","Great job","Terrific","You get a gold star","Well done","tray bien","dway","muey beuno","exacto")
$Array_GetBackUpOnTheHorse = @("Doh","Oops","Almost - try again","Not quite","Nope","Thats not it","Nice try buddy","Not so much","No soup for you!","Bummer dude!","If at first you dont succeed try, try again","Nahhh","Bu dway")

# Note: if you're attempting to execute this in PowerShell6 or PowerShell7 you won't hear anything
# This .dll is from .Net, whereas PS6 and 7 are .Net CORE and that API is not ported.
# More here re: PS6 https://github.com/PowerShell/PowerShell/issues/8809
# And the ongoing discussion here re: PS7 https://github.com/dotnet/wpf/issues/2935
Add-Type -AssemblyName System.Speech
$Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
$Speech.Speak("Do  you want to play a game? Enter times table of your choice, or just hit enter for all tables up to 12. Make any other entry and i'll focus on Tables 6 to 9.")

#   Pick your poison
Write-Host "Enter Times Table of your choice, or just hit enter for all Tables up to 12."
$InitTable = Read-Host -Prompt ("Make any other entry and i'll focus on Tables 6 to 9")
$Table = $InitTable

while($true) {
    If ($InitTable -eq "") {
    $Table = (Get-Random -Minimum 1 -Maximum 13)
    }
    Elseif ($InitTable -NotIn 1..12) {
        $Table = (Get-Random -Minimum 6 -Maximum 10) 
    } 
        [Int]$Factor = (Get-Random -Minimum 1 -Maximum 13)
        [Int]$Product =  [Int]$Table * $Factor
        $Assignment = "$Table x $Factor"
        $Speech.Speak("$Table times ;$Factor equals")
        $Answer = Read-Host -Prompt $Assignment
        if ($Answer.Length -gt 0) {
            if ($Product -eq $Answer) {
                Write-host "Correct" -ForegroundColor "Green"
                Write-host "---"
                $Recognition = $Array_AttaKiddo | Get-Random
                $Speech.Speak("$Recognition. You entered $Answer. $Table times $Factor equals $Product.")
            }
    #      '^\d+$' == regex for 'only numbers'
           elseif ($Answer -NotMatch '^\d+$') {
               Write-Host "The correct answer is $Product"
               Write-host "---"
               $Speech.Speak("That was not a number. The correct answer is $Product.")
            } 
            elseif ($Product -ne $Answer) {
                Write-host "Incorrect" -ForegroundColor "Red"
                Write-host "The correct answer is $Product"
                Write-host "---"
    #           Get a GetBackUpOnTheHorse (alternate way to get random element from the array v. AttaKiddo above)
                $Recognition = Get-Random -InputObject $Array_GetBackUpOnTheHorse
                $Speech.Speak("$Recognition. You should have entered ;$Product, but you entered ;$Answer. $Table times $Factor equals $Product.")
            }
        }
        else {
            Write-Host "The correct answer is $Product"
            Write-host "---"
            $Speech.Speak("You did not provide an answer. The correct answer is $Product.")
    }
}