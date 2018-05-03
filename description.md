##Delete Empty Chunks
Delete chunks which contain no player entities. Useful for slimming down save files and recovering lost performance from fruitless exploration. Can configure radius of adjacent chunks to keep and toggle keeping chunks with paving

Based on [DestroyEmptyChunks](https://mods.factorio.com/mods/darkfrei/DestroyEmptyChunks) v0.0.5 by darkfrei

##Version History:

###v0.3.2 (2018-05-02)
* Surface.count_tiles_filtered now accepts a table of filters in Factorio 0.16.40
* Prevent deleting the chunk a player is in when that chunk has not yet been charted

###v0.3.1 (2018-03-11)
* Added support for RSO. Unavoidable side effects: Because of the way RSO handles resource generation, if you've 'pinned' part of a resource, RSO will create an identical resource shifted by a bit within that region. If you delete the starting area chunks, those resources are gone. Otherwise, if RSO is allowed to regenerate them, it will spam the starting area with duplicates as many times as one clicks the button.

###v0.3.0 (2018-03-04)
* No need to search invisible chunks for player entities or paving (nearly three times faster)
* Removed hard-coded enumeration of tile names from other mods
* Now detect all non-vanilla tiles as paving added by other mods except those specifically ignored
* Cleaned up log and print messages
* Limited to only deleting chunks from a single surface specified by an option. It is not reliably safe to delete chunks from surfaces added by mods

###v0.2.3 (2018-03-01)
* Updated for Refined Concrete in Version 0.16.27

###v0.2.2 (2018-01-01)
* Corrected typo causing multiplayer to fail

###v0.2.0 (2018-01-01)
* Improved support for localization
* Ignore Factorissimo2 factories
* Added support for [AsphaltRoads](https://mods.factorio.com/mods/Arcitos/AsphaltRoads)
* Refactored code

###v0.1.1 (2017-12-30)
* Optimizations, 7 times faster processing paving

###v0.1.0 (2017-12-29)
* Backported bugfixes from DestroyEmptyChunks 0.2.1
* Allowed for paving other than concrete.
* Updated for 0.16

###v0.0.7 (2017-10-03)
* Initial Release.
