# 16th Note
A three hour project designed to add combat and ambient music to Garry's Mod gameplay, similar to Nombat. However, Nombat is rather old and the process to creating music with the addon is time consuming and discouraging for most inexperienced with LUA.
This addon aims to be a better alternative.

### What does "16th Note" have over Nombat?
16th Note takes what Nombat does and improves upon it. Such as the following:

* Massively improves user experience when it comes to creating music addons
* Internal code is neater (imo) when compared to Nombat
* You are not forced to have both ambient and combat tracks in an addon. You can have only either ambient or combat if you desire. (If you deem this an improvement) 

That's pretty much it.

# Nombat Support
Because there are a plentiful amount of Nombat music packs in the workshop, it would be odd to throw away music pack options because a player would use 16th Note over Nombat so support with Nombat music packs was added.

**All you have to do to utilize the support is to simply download any Nombat music pack and 16th Note will automatically integrate it into 16th Note's system.**

Example addon:
https://steamcommunity.com/sharedfiles/filedetails/?id=2605682850&searchtext=nombat

# Creating 16th Note music addons
16th Note features a very simple method of creating ambient/combat music addons. The method boils down to simply placing .mp3 files in either an ambient or combat folder and the addon handles the rest. 

For the following guide, I will be using GTFO soundtrack.

### Quick Guide
For experienced users, this is the filepath to add music to 16th note:
`{ADDONNAME}/sound/16thnote/{UNIQUE PACK NAME}/ambient AND combat/{MP3 files in either folder}`
> Note: AND means create a folder named ambient and another named combat

### Step by Step Guide
To start, create a folder with whatever name you want. Here I named the folder "16thnote_gtfo"

![image](https://github.com/user-attachments/assets/74a670c9-a2f6-44ed-80dd-819219a14a7c)

Next, inside the root folder you created, create a folder named "sound"

![image](https://github.com/user-attachments/assets/9d11406b-5a31-4fc6-8b71-8ee412125420)

Inside the sound folder, create another folder named "16thnote"

![image](https://github.com/user-attachments/assets/16514de4-b096-4975-adee-b287d999650d)

Now inside the 16thnote folder, create another folder with any name you wish, make sure it is unique and conveys what game/ost it is representing. The spawnmenu will reflect what is given here.

![image](https://github.com/user-attachments/assets/88da7d5a-ced2-4668-bcef-fed8cd37be40)

The last folders you want to create inside your new folder is both "ambient" and "combat" 

![image](https://github.com/user-attachments/assets/29ece8d5-494e-4352-bd15-41fabf6682df)

After that, all you have to do is drop .mp3 files into either the "ambient" or "combat" folders, depending on what you want as shown below. 16th Note will handle the rest after this point so this means you are officially done!
The .mp3 file names can be anything **as long as the name involves only letters and numbers and no double spaces**

![image](https://github.com/user-attachments/assets/c8a5fb55-cb98-4f92-8456-c4a53e60653f)
