# inspired by, and built upon
# https://www.reddit.com/r/PowerShell/comments/ikoy4c/how_i_got_my_6_year_old_to_practice_the_alphabet/
# by u/_lahell_  https://www.reddit.com/user/_lahell_/
#
# as i needed an excuse to get my slightly older kiddo to a) practice her times tables, and b) start to code
# So now she needs to fire up VSCode and powershell for 10min a day... 
#

# Define Arrays including... 
# AttaKiddo and GetBackUpOnTheHorse
# used to provide some variation in spoken responses
$Array_AttaKiddo = @("Great Job!","fish on!","Congrats","Hoo rahh","Correct","Booyakasha diggity check this out","Boom","Way to go","Play on, player","High Five","Cheers","Woot","Homerun","wicked","superb","Impressive","Awesome","Great job","Terrific","You get a gold star","Well done","tray bien","dway","moi bwaino","exacto","Hey hey boo boo-- you're smarter than the average bear","Here i come to save the day","To infinity and beyond!","yeba daba doo","digga dunch!","oh Kent","yeet!","yippee kai yay","aint no stoppin us now, weir on the move","hot diggity dog","heidy ho","who ha")
$Array_GetBackUpOnTheHorse = @("uh uh","nyet","boo shir da","that one snapped the line","lathose","you are mistaken","unsuitable","beam me up scotty","that one got away from you","error","insanity laughs under pressure weir cracking, cant we give ourselves one more chance?","does not compute","people forget. forget theyre hiding behind an eminence front","illogical","off target","goose aige","air ball","meh","Doh","Oops","Almost - try again","Not quite","Nope","Thats not it","Nice try buddy","Not so much","No soup for you!","Bummer dude!","If at first you dont succeed try, try again","Nahhh","Boo dway","Dratz","Foiled again","You blockhead!","Heavens to Murgatroid","Thats all i can stand and i cant stands no more","Sufferin Succotash!","Ay caramba","Good grief","Zoinks","and i guess thats why they call it the blues","im gonna say it yeah... go back to scoolin","No-- i don't think so")
# and the couple standard speakers (for US Windows installs)
$Array_Speaker = @("Zira","David")
# This next one i'm going to keep appending... so rather than
#   $Array_KeepScore += 1     (or 0 for a wrong answer)
# for each new correct answer which would lead PS to create a new array
# and then copy all old elements into it and append the new one... i'm going to use an ArrayList which
# should allow me to more efficiently append to the existing list with
#   [void]($ArrayList_KeepScore.Add(1))     (or 0 for a wrong answer)
# more/less per: https://pscustomobject.github.io/powershell/Add-Remove-Items-From-Array/
$ArrayList_KeepScore =[System.Collections.ArrayList]@()

# Note: if you're attempting to execute this in PowerShell6 or PowerShell7 you won't hear anything
# This .dll is from .Net, whereas PS6 and 7 are .Net CORE and that API is not ported.
# More here re: PS6 https://github.com/PowerShell/PowerShell/issues/8809
# And the ongoing discussion here re: PS7 https://github.com/dotnet/wpf/issues/2935
Add-Type -AssemblyName System.Speech
$Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
$Speech.Speak("Do  you want to play a game? Enter times table of your choice $env:USERNAME, or just hit enter for all tables up to 12. Make any other entry and i'll focus on Tables 6 to 9.")

# define a few variables as well
# play for
$nMin = 10

# and explicitly making the vars in the function 'script' scope... such that they are available outside the scope of
# where the function's called from. eg. in this way, at the end, the variables/values are ALSO available for use.
function KeepScore() {
    $script:TotalAsked = $ArrayList_KeepScore.Count
    $script:TotalCorrect = ($ArrayList_KeepScore | Measure-Object -sum).sum
#  not actually using incorrect calc. This app's all about positive reinforcement
#   $TotalWrong = $TotalAsked - $TotalCorrect
    $script:PercentRight = ($TotalCorrect / $TotalAsked) * 100
    }



#   Pick your poison
Write-Host "Enter Times Table of your choice, or just hit enter for all Tables up to 12."
$InitTable = Read-Host -Prompt ("Make any other entry and i'll focus on Tables 6 to 9")
$Table = $InitTable

$TheEnd = (Get-Date).AddMinutes($nMin)
while ((Get-Date) -lt $TheEnd) {
# Do stuff
# OR no timer comment out above and uncomment below while($true)
#while($true) {
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
            if ($Answer -eq "exit") {
                $Speech.Speak("C yuh! peace out")
                exit
            }
            if ($Answer -eq "lol") {
                $Speech.Speak("Ha Ha Ha. Now get back to the game child.")
# not 'KeepingScore' in this case and counting this as a wrong answer... albeit i could
# implicitly, they already 'lost' time so won't get as many right as they could have. 
# will consider that penalty enough for the high achiever, who also chooses to play a little class clown at test time ;-)
# i know this child
                Write-Host "The correct answer is $Product"
                Write-host "---"
            } 
            elseif ($Product -eq $Answer) {
                [void]($ArrayList_KeepScore.Add(1))
                KeepScore
                Write-host "Correct" -ForegroundColor "Green"
                if (($ArrayList_KeepScore.count/10) -is [Int] -and $PercentRight -ge 60) {
                    Write-host "So far you've scored $TotalCorrect out of $TotalAsked, or $PercentRight%"
                    }
                Write-host "---"
                $Recognition = $Array_AttaKiddo | Get-Random
				$GirlBoy = $Array_Speaker | Get-Random
				$Speech.SelectVoice("Microsoft $GirlBoy Desktop")
                $Speech.Speak("$Recognition. You entered $Answer. $Table times $Factor equals $Product.")
            }
    #      '^\d+$' == regex for 'only numbers'
           elseif ($Answer -NotMatch '^\d+$') {
# again, not 'KeepingScore' in this case 'typo' case-- not counting this as a wrong answer...
# if you felt, your student was 'gaming' the system and using this case as a way to bump up their scoring
# feel free to change the code, and count this as a wrong answer
               Write-Host "The correct answer is $Product"
               Write-host "---"
               $Speech.Speak("That was not a number. The correct answer is $Product.")
            } 
            elseif ($Product -ne $Answer) {
                [void]($ArrayList_KeepScore.Add(0))
                KeepScore
                Write-host "Incorrect" -ForegroundColor "Red"
                Write-host "The correct answer is $Product"
                Write-host "---"
    #           Get a GetBackUpOnTheHorse (alternate way to get random element from the array v. AttaKiddo above)
                $Recognition = Get-Random -InputObject $Array_GetBackUpOnTheHorse
				$GirlBoy = $Array_Speaker | Get-Random
				$Speech.SelectVoice("Microsoft $GirlBoy Desktop")
                $Speech.Speak("$Recognition. You should have entered ;$Product, but you entered ;$Answer. $Table times $Factor equals $Product.")
            }
        }
        else {
# in this case, we'll count this 'pass' against the student for scoring purposes
# if you choose not to decide you still have made a choice!
# consequences ensue
            [void]($ArrayList_KeepScore.Add(0))
            KeepScore
            Write-host "No answer provided" -ForegroundColor "Yellow"
            Write-Host "The correct answer is $Product"
            Write-host "---"
            $Speech.Speak("You did not provide an answer $env:USERNAME. The correct answer is $Product.")
    }
}
$Speech.SelectVoice("Microsoft David Desktop")
$Speech.Speak("Greetings Professor Falken. Hello. A strange game. How about a nice game of Chess?")
$RndPercentRight = [math]::Round($PercentRight,2)
Write-Host "Final Tally: you answered $TotalCorrect correctly of $TotalAsked questions asked, or a $RndPercentRight% in","$nMin","min."
$Speech.Speak("Seriously... you scored '$TotalCorrect' out of '$TotalAsked', or '$RndPercentRight' percent in '$nMin' minutes.")
$s = $env:POWERSHELL_DISTRIBUTION_CHANNEL
$s = $s.split(":")[1]
$Speech.Speak("And... for what it's worth. I enjoyed running on your '$s' PC, sporting an '$env:PROCESSOR_IDENTIFIER' processor... $env:USERNAME")
