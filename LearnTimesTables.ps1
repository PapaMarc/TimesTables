# inspired by, and built upon
# https://www.reddit.com/r/PowerShell/comments/ikoy4c/how_i_got_my_6_year_old_to_practice_the_alphabet/
# by u/_lahell_  https://www.reddit.com/user/_lahell_/
#
# as i needed an excuse to get my slightly older kiddo to a) practice her times tables, and b) start to code
# So now she needs to fire up VSCode and powershell for 10min a day... 
#
# Load / Prep Speech assembly
# Note: if you're attempting to execute this in PowerShell6 or PowerShell7 you won't hear anything
# This .dll is from .Net, whereas PS6 and 7 are .Net CORE and that API is not ported.
# More here re: PS6 https://github.com/PowerShell/PowerShell/issues/8809
# And the ongoing discussion here re: PS7 https://github.com/dotnet/wpf/issues/2935
Add-Type -AssemblyName System.Speech
$Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer


# Define Arrays including... 
# AttaKiddo and GetBackUpOnTheHorse
# used to provide some variation in spoken responses
$Array_AttaKiddo = @("Great Job!","fish on!","Congrats","Hoo rahh","Correct","Booyakasha diggity check this out","Boom","Way to go","Play on, player","High Five","Cheers","Woot","Homerun","wicked","superb","Impressive","Awesome","Great job","Terrific","You get a gold star","Well done","tray bien","dway","moi bwaino","exacto","Hey hey boo boo-- you're smarter than the average bear","Here i come to save the day","To infinity and beyond!","yeba daba doo","digga dunch!","oh Kent","yeet!","yippee kai yay","aint no stoppin us now, weir on the move","hot diggity dog","heidy ho","who ha")
$Array_GetBackUpOnTheHorse = @("uh uh","nyet","boo shir da","that one snapped the line","lathose","you are mistaken","unsuitable","beam me up scotty","that one got away from you","err ror. does not compute.","insanity laughs under pressure weir cracking, cant we give ourselves one more chance?","does not compute","people forget. forget theyre hiding behind an eminence front","illogical","I still have the greatest enthusiasm and confidence in the mission","off target","goose aige","air ball","meh","Doh","Oops","Almost - try again","Not quite","Nope","Thats not it","Nice try buddy","Not so much","No soup for you!","Bummer dude!","If at first you dont succeed try, try again","Nahhh","Boo dway","Dratz","Foiled again","You blockhead!","Heavens to Murgatroid","Thats all i can stand and i cant stands no more","Sufferin Succotash!","Ay caramba","Good grief","Zoinks","and i guess thats why they call it the blues","im gonna say it yeah... go back to scoolin","No-- i don't think so")
# and the couple standard speakers (for US Windows installs)
$Array_Speaker = @("Zira","David")
# This next one i'm going to keep appending... so rather than
#   $Array_KeepScore += 1     (or 0 for a wrong answer)
# for each new correct answer which would lead PS to create a new array
# and then copy all old elements into it and append the new one... i'm going to use an ArrayList which
# should allow me to more efficiently append to the existing list with
#   [void]($ArrayList_KeepScore.Add(1))     (or 0 for a wrong answer)
# more/less per: https://pscustomobject.github.io/powershell/Add-Remove-Items-From-Array/
# BUT WAIT... there's more, so don't use this either:
#   $ArrayList_KeepScore =[System.Collections.ArrayList]@()
# on further investigation, looks like 'ArrayList' may be deprecated soon, in favor of 'List'
# see: https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/
# so instead use this:
[System.Collections.Generic.List[int]]$list_KeepScore = @()
# and fyi... from PS5.1 and up this shorter version works:   [List[int]]$list_KeepScore = @()

# define a hash table,
# and another which is a special case at that-- an 'ordered dictionary'
# will add an entry each time a TimesTable Assignment or problem is missed
#$script:InputObject = @{}
$script:ht_missed = [System.Collections.Specialized.OrderedDictionary]@{}

# define variable(s) as well
# play for
$nMin = 10
#Feel free to replace $env:USERNAME with a name in quotes eg. "Jane"
$Student = $env:USERNAME

# i've been incrementally refactoring the code so... it's a bit of a mutt and is increasingly more object oriented,
# relative to the initial procedural code base that inspired me... 
# This is occuring primarilly as i iteratively add functionality (to persist and review missed tables, historical reporting, etc.) and bug fix
# though at the same time i'll admit some corner case find/fix has resulted in additional procedural remedy
# apologies to the purists out there from this pragmatist.


# Accordingly... define some functions:

# and explicitly making some vars used in the functions 'script:' scope as needed... such that they are available outside the scope of
# where the function's called from. eg. in this way, at the end, the variables/values are ALSO available for use.
function KeepScore() {   #iteratively grades today's exercise / quiz as each TimesTable Assignment is completed
    $script:TotalAsked = $list_KeepScore.Count
    $script:TotalCorrect = ($list_KeepScore | Measure-Object -sum).sum
#  not actually using incorrect calc. This app's all about positive reinforcement
#   $TotalWrong = $TotalAsked - $TotalCorrect
    $script:PercentRight = ($TotalCorrect / $TotalAsked) * 100
    }
 function PersistScore() {
    RetrieveScoreHistory
    $ht_PerfToday = [System.Collections.Specialized.OrderedDictionary]@{}
    $dt = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
    $ht_PerfToday = @{$dt = @{Correct = $TotalCorrect; Asked = $TotalAsked; Score = $RndPercentRight; nMin = $nMin }}
    $PerfTodayJson = $ht_PerfToday | ConvertTo-Json -depth 3
    $exist = Test-Path -Path .\PerfToDateJson.txt
        if ($exist -eq 'True') {
            # add-content cmdlet didn't work great beyond the first entry...
            # nth element should be added with a comma v curly braces at start and end
            # so now reading it prior (above), manually hand editing and
            # binding the old set with the newest element so it's properly formatted json
            # eg. handmade 'appendJsonProperly'
            $tJs1a = $jsonObjScores | ConvertTo-Json -depth 3  #get the object into Json format
            $tJs1a = $tJs1a.Substring(0,$tJs1a.Length-3) #drop the last 1 character (which is a closing curly brace eg. "}")
            $tJs2a = $PerfTodayJson | Out-String
            $tJs2b = $tJs2a.substring(1) #trim starting (curly brace) char off the $PerfTodayJson as string
            $TweakJson = "$tJs1a" , "$tJs2b" -join ","
#            Set-Content -Path .\TestJsonMerge.txt -Value "$TweakJson"
            # and then re/overwriting the entire file contents
            Set-Content -Path .\PerfToDateJson.txt -Value "$TweakJson"    
        } else {
        Set-Content -Path .\PerfToDateJson.txt -Value $PerfTodayJson
        }
    }

function RetrieveScoreHistory() {
    $exist = Test-Path -Path .\PerfToDateJson.txt
        if ($exist) {
        $script:ht_PastScores = [System.Collections.Specialized.OrderedDictionary]@{}
        #retrieve json from file
        $script:jsonObjScores = Get-Content -Path .\PerfToDateJson.txt | ConvertFrom-Json
        #put it into a (ordered dictionary) hashtable
        foreach ($property in $jsonObjScores.PSObject.Properties) {
            $ht_PastScores[$property.Name] = $property.Value
            }
        }
        else {
            write-host "No prior scoring history yet... but soon enough! :-)"
            }
    }
function DisplayScoreHistory() {
        Write-Host "Here is a summary of your past performance:"
        $c = 0 
            foreach ($key in $ht_PastScores.keys) { 
                $dt = $key
                $correct=$ht_PastScores[$c].correct
                $asked=$ht_PastScores[$c].asked
                $nMin=$ht_PastScores[$c].nMin
                $Score=$ht_PastScores[$c].score
                Write-Host "$dt",": $correct of $asked answered correctly, or $score% in","$nMin","min."
                $c++
                }
            write-host "-"
            $Speech.Speak("Here is an enumeration of your prior scoring,,,")
        }
function ReadMissedTT_JsonToPSObjToHT() {
    $jsonObj = Get-Content -Path .\TTMissedJson.txt | ConvertFrom-Json
    foreach ($property in $jsonObj.PSObject.Properties) {
        $ht_missed[$property.Name] = $property.Value
        }
    }
    
function ReCapMissedTT() {              #displays the 'most recently' missed TimesTables / Assignments at start and end of the exercise
#    $ht_missed | ConvertTo-Json -depth 3  # dumps out the Json
    $c = 0 
    foreach ($key in $ht_missed.keys) {
#    write-host $key ; $ht_missed[$key].values   #works... writes/auto-formats prob# and Table and Factor vertically
    $ProbNo = $key 
#    $stuff = $ht_missed[$key].values            #works... 
#    write-host $stuff                           #writes/auto-formats Tab and Factor horizontally
#        $i=$ht_missed.keys.count   #don't really need this... not using, but interesting to moi
        [Int]$Tab = $ht_missed[$c].table
        [Int]$Fac = $ht_missed[$c].factor
        $Prod = $Tab * $Fac
        write-host "#$ProbNo",':',"  $Tab * $Fac = $Prod"
        write-host '-'
        $c++   # $c=$c+1  (increment counter so that Factor is then retrieved on 2nd pass)
        }
    }   

function RecordMissedTT() {
    [string]$Str_QuesNum = $TotalAsked
    $script:ht_missed = $script:ht_missed + @{$Str_QuesNum = @{Table = $Table; Factor = $Factor}}
}

function PersistMissedTT_HTasJson () {
    $missedJson = $script:ht_missed | ConvertTo-Json -depth 3
    Set-Content -Path .\TTMissedJson.txt -Value $missedJson
}

# Intro
    $Speech.Speak("Do  you want to play a game?")

# ReCap scoring history
RetrieveScoreHistory
DisplayScoreHistory

# Intro
# ReCap Last misses...
$missedFile = Test-Path -Path .\TTmissedJson.txt
if ($missedFile -eq 'False') {
    ReadMissedTT_JsonToPSObjToHT
    Write-Host "Last time you missed these. Give them a quick review... you'll get'em this time around!"
    ReCapMissedTT
    $Speech.Speak("Last time you missed these. Give them a quick review... you'll get'em this time around!")
    #clear ordered dictionary via reinitializing.
    $script:ht_missed = [System.Collections.Specialized.OrderedDictionary]@{}
}

# Pick your poison.
$Speech.Speak("Please make an entry and i'll focus on what you request:")
Write-Host "Enter Times Table of your choice [1-12]"
Write-Host "or just hit enter for all Tables up to 12 [Enter]"
Write-Host "Make any other entry and i'll focus on Tables 6 to 9 [xyz]" #aka the 'meat' of the exercise... tables 6-9
# and collect input a slightly different way then elsewhere primiarlly because I want to
# clear out input buffer so in the event someone was impatient waiting for the speaker to finish
# and hit enter 5 times they won't get all tables and the first 4 wrong...
$HOST.UI.RawUI.Flushinputbuffer()
$InitTable = [Console]::ReadLine()
$script:Table = $InitTable

# Main... if we can take the liberty of calling it that
$TheEnd = (Get-Date).AddMinutes($nMin)
while ((Get-Date) -lt $TheEnd) {
# Do stuff
# OR no timer comment out above 2 and uncomment below while($true)
# while($true) {
    If ($InitTable -eq "") {
    $Table = (Get-Random -Minimum 1 -Maximum 13)
    }
    Elseif ($InitTable -NotIn 1..12) { #then do the 'meat' of the exercise
        $Table = (Get-Random -Minimum 6 -Maximum 10) 
    } 
        [Int]$script:Factor = (Get-Random -Minimum 1 -Maximum 13)
        [Int]$Product =  [Int]$Table * $Factor
        $Assignment = "$Table x $Factor"
        $Speech.Speak("$Table times ;$Factor equals")
        $HOST.UI.RawUI.Flushinputbuffer() #again... this clears out the input buffer immediately prior to prompt
		$Answer = Read-Host -Prompt $Assignment
        if ($Answer.Length -gt 0) {
#           wants to quit
            if ($Answer -eq "exit") {
                $Speech.Speak("C yuh! peace out")
                exit
            }
            if ($Answer -eq "lol") {
#               ad-hoc testing... enters "lol"  Just for giggles, let's handle this.
                $Speech.Speak("Ha Ha Ha. Now get back to the game child.")
# not 'KeepingScore' in this case and counting this as a wrong answer... albeit i could
# implicitly, they already 'lost' time so won't get as many right as they could have. 
# will consider that penalty enough for the high achiever, who also chooses to play a little class clown at test time ;-)
# i know this child
                Write-Host "The correct answer is $Product"
                Write-host "---"
            } 
            elseif ($Product -eq $Answer) {
#               gets answer correct... a '1' is a true or correct answer
                [void]($list_KeepScore.Add(1))
                KeepScore
                Write-host "Correct" -ForegroundColor "Green"
                if (($list_KeepScore.count/10) -is [Int] -and $PercentRight -ge 60) {
                    Write-host "So far you've scored $TotalCorrect out of $TotalAsked, or $PercentRight%"
                    }
                Write-host "---"
                $Recognition = $Array_AttaKiddo | Get-Random
				$GirlBoy = $Array_Speaker | Get-Random
				$Speech.SelectVoice("Microsoft $GirlBoy Desktop")
                $Speech.Speak("$Recognition. You entered $Answer.")
                $Speech.Rate = 3
                $Speech.Speak("$Table times $Factor equals, $Product.")
                $Speech.Rate = 0
            }
#           '^\d+$' == regex for 'only numbers'
           elseif ($Answer -NotMatch '^\d+$') {
# again, not 'KeepingScore' in this case 'typo' case-- not counting this as a wrong answer...
# if you felt, your student was 'gaming' the system and using this case as a way to bump up their scoring
# feel free to change the code, and count this as a wrong answer
               Write-Host "The correct answer is $Product"
               Write-host "---"
               $Speech.Speak("That was not a number. The correct answer is $Product.")
            } 
            elseif ($Product -ne $Answer) {
#               wrong answer... a '0' is a false or wrong answer
                [void]($list_KeepScore.Add(0))
                KeepScore
#               and let's record the missed problem in our hashtable
#                $ht_missed = $ht_missed + @{$TotalAsked = $Assignment}
# want the missed question# as a string for the HT key... not an INT... 
# for Json cmdlet requirements wrt persisting and reading it out later
                RecordMissedTT
                Write-host "Incorrect" -ForegroundColor "Red"
                Write-host "The correct answer is $Product"
                Write-host "---"
#               Get a GetBackUpOnTheHorse (alternate way to get random element from the array v. AttaKiddo above)
                $Recognition = Get-Random -InputObject $Array_GetBackUpOnTheHorse
				$GirlBoy = $Array_Speaker | Get-Random
				$Speech.SelectVoice("Microsoft $GirlBoy Desktop")
                $Speech.Speak("$Recognition. You should have entered ;$Product, but you entered ;$Answer. $Table times $Factor equals $Product.")
            }
        }
        else {
# in this case (they didn't provide an answer and hit ENTER) we'll count this 'pass' against the student for scoring purposes
# if you choose not to decide you still have made a choice!
# consequences ensue
            [void]($list_KeepScore.Add(0))
            KeepScore
#           again let's incrementally record the missed problem in our hashtable (by adding another hashtable 'row')
            RecordMissedTT
            Write-host "No answer provided" -ForegroundColor "Yellow"
            Write-Host "The correct answer is $Product"
            Write-host "---"
            $Speech.Speak("You did not provide an answer $Student. The correct answer is $Product.")
    }
}

# Closing
$Speech.SelectVoice("Microsoft David Desktop")
$Speech.Speak("Greetings Professor Falken, A strange game. How about a nice game of Chess?")
$RndPercentRight = [math]::Round($PercentRight,2)
Write-Host "Final Tally: you answered $TotalCorrect correctly of $TotalAsked questions asked, or a $RndPercentRight% in","$nMin","min."
$Speech.Speak("Seriously... you scored '$TotalCorrect' out of '$TotalAsked', or '$RndPercentRight' percent in '$nMin' minutes.")
PersistScore
if ([Int]$RndPercentRight -lt 100) {
    # then let's enumerate what was missed
    Write-Host "Here are the ones you missed:"

# $ht_missed | ConvertTo-Json -depth 3          #works... dumps to screen json
# $ht_missed | ConvertTo-Xml -As String         #works... dumps to screen as xml

    ReCapMissedTT
    # persist/replace prev persisted MISSED
    PersistMissedTT_HTasJson
    
    $Speech.Speak("Here's what you missed. Review these... and you'll get'em next time!")
    }
    elseif  ([Int]$RndPercentRight -eq 100) {
    $Speech.Speak("Flawless.")
    $Speech.SelectVoice("Microsoft Zira Desktop")
    $Speech.Speak("Great job!")
    $exist = Test-Path -Path .\TTMissedJson.txt
        if ($exist) {
        Remove-Item -Path .\TTMissedJson.txt    #iff prior TTMisses are persisted, delete the file so next startup it won't reCap any misses in this Flawless 100% case
        }
    }
#   and just for a little more fun with speech before we go...
$Speech.SelectVoice("Microsoft David Desktop")
$s = $env:POWERSHELL_DISTRIBUTION_CHANNEL
$s = $s.split(":")[1]
$Speech.Speak("And... for what it's worth. I enjoyed running on your '$s' PC, sporting an '$env:PROCESSOR_IDENTIFIER' processor... $Student")