#Description#
**A combinator that can set the recipe of an assembler (or other machine) based on signal inputs for any and all of your automation needs. There's also a combinator to get recipe ingredients.**

-------------

#How to#
Simply place the combinator facing any assembler (modded ones should work too).
The signals are: the item with matching name to the recipe or, if such item doesn't exist (fill/empty oil barrels and other fluid related recipes in vanilla), select the appropriate virtual signal (localization is an issue here - mods' recipes will not have proper names).
When there's no signal fed into the combinator, it'll set the assembler to nothing.
When the recipe is changed, items from the assembler are moved to an invisiable active provider chest where your bots can pick them up. This can be disabled by switching the combinator to 'off' (it'll still set recipes).

The recipe combinator outputs ingredients of a recipe. It now also outputs the time multiplied by 10 (combinators only work with integers).

**You can also ask questions on the [forum](https://forums.factorio.com/viewtopic.php?f=93&t=34405)!**

#Localisation#
All vanilla "virtual recipes" should be localised (English only for now) but if you have other mods you can use [this mod](https://mods.factorio.com/mods/theRustyKnife/crafting-combinator-locale) for proper naming and localisation.

#Credits#
**[LuziferSenpai](https://mods.factorio.com/mods/LuziferSenpai) for the original idea and some of the code.** 
[me](https://mods.factorio.com/mods/theRustyKnife) for the rest of the code.
[Igie](https://mods.factorio.com/mods/theRustyKnife/crafting_combinator/discussion/4421) for the recipe combinator idea.

-------------

#Changelog#
##0.3.3##
* Fixed a crash caused by a rounding error in recipe combinator

##0.3.2##
* Fixed crash when placing a combinator after reloading a game ([5908](https://mods.factorio.com/mods/theRustyKnife/crafting_combinator/discussion/5908))

##0.3.1##
* Fixed wrong path for no-icon icon and an error in migration script ([5869](https://mods.factorio.com/mods/theRustyKnife/crafting_combinator/discussion/5869))

##0.3.0##
* Completely rewritten code
* Moved special cases to the locale mod
+ Added support for external special case and icon definitions
+ Added an invisible active provider chest where the items from the assembler are put when recipe changes

##0.2.2##
+ Added crafting time to recipe combinator output (thanks to [LuziferSenpai](https://mods.factorio.com/mods/theRustyKnife/crafting_combinator/discussion/4654))

##0.2.1##
* Fixed a crash when removing a recipe combinator in a new game ([4644](https://mods.factorio.com/mods/theRustyKnife/crafting_combinator/discussion/4644))

##0.2.0##
* Moved localisation into another mod
+ Added recipe combinator (thanks to [Igie](https://mods.factorio.com/mods/theRustyKnife/crafting_combinator/discussion/4421))

##0.1.4##
* Changed to work with any and all (hopefully) crafting machine (chemplants, refineries too)
+ Added locale for some mods

##0.1.3##
* Recipe for combinator is enabled when the mod is added to the game

##0.1.2##
+ Added a special case system to solve a recipe naming problem
+ Translations for vanilla virtual recipes

##0.1.1##
+ Initial release

