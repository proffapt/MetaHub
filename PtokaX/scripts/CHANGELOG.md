2016-01-08
----------

- Provide a `-m` flag for the `addto` command to send notices to mainchat.

2015-05-03
----------

- Operators can enable/disable mainchat for unregistered users by using `!mainchat on/off`.
- Errors are sent to `OpChat` instead of PM to **'`hjpotter92`'**.
- Operators can set the minimum share requirement flag on/off with `!minshare on/off`.

2015-04-19
----------

- Add `lunarise` and `unlunarise` custom commands, which display messages in leet.
- Fix `RegDisconnected`, `OpDisconnected` and `UserDisconnected` in `external/metabolism/expel.lua`.
- Allowed profiles can lunarise themselves.

2015-04-04
----------

- Add `+history` and `+list` command to `#[ModzChat]` and `#[VIPChat]`.
- Fix `sLogPath` for `subroom.lua`

2015-03-07
----------

- Add hub topic ticker feature.
- Users with permission to update topics can activate tickers.
- New tickers can be added by users with sufficient profile permission.
- Optional `-u` flag can be passed whick adding tickers to add message from someone else.

2015-02-19
----------

- Ban users for an interval of 1 hour if connecting in _passive_ mode.
- Rewrite the restriction scripts. No more squashed up definitions or overwriting variables.

2015-02-09
----------

- Code cleanup for chat logger script.
- Use hash tables for command execution instead of `if-else` statement blocks.
- Fix the conversion of `&amp;` etc. entities before writing to log file.

2014-11-30
----------

- Stop displaying `+ul` info on mainchat without `-m` flag.
- Add two templates for `[BOT]Info` additions.

2014-08-19
----------

- Remove user logging script due to detrimental effects on database.
- Optimize directory structure.

2014-08-17
----------

- Add chat history for each chatroom.
- Establish user command to access chat history.

2014-04-29
----------

- Add profile based chatrooms, such as `#[ModzChat]` for moderator profile holders.
- Script to save all profiles, registration etc. details every 10 minutes.
- List custom commands when using `!help` command.
- Alias `!custhelp` for custom commands only.
- Fix an unreported bug for `[BOT]Info` regarding the notifications sent to users when fulfilling a request or closing a thread.

2014-03-27
----------

- Right click commands for reporting updated.
- Various context menu commands supported based on documentation [here](https://github.com/HiT-Hi-FiT-Hai/hhfh-docs/wiki/Custom-user-commands).
- Notify user of the report on success.

2014-03-23
----------

- `[BOT]Offliner` accepts multiple IDs for deletion commands.
- Support for adding more than one magnet to same entry.
- Enhanced error reporting to end users'.
- Deliver messages directly for offline message service if recipient is online. Previously, all messages were stored.

2014-03-02
----------

- `[BOT]Offliner` stores the file display name from magnet URI scheme.
- Using a stored procedure to insert magnets and entries.
- Long pending bug regarding kicks from a lower profile user fixed.

2014-02-19
----------

- Operators can promote users to moderators in each chatroom.
- Chatroom moderators can kick several users in a single command.

2013-11-29
----------

- Normalize tables
- Optimise storage and searches for `[BOT]Offliner`.

2013-09-17
----------

- Subscription based mainchat.
- Additional commands for normal to administrative users.
- Auto registration system based on boolean flag set by operator status users.
- Certain [BOT]Info commands updated to be usable only by registered users.

2013-08-29
----------

- Fix chatrooms' `invite` command bug.
- Quicker access to subscribers list in chatrooms, thereby reducing table access times.
- Fix an unreported bug in `kick` command wherein non-alphanumeric characters weren't allowed.
- Subscribers' list in chatrooms modified to show number of subscribers.

2013-08-22
----------

- Advanced search to support category based searches (for `[BOT]Offliner`).
- Commands specific to bots restricted back to PM only.

2013-07-26
----------

- New API for chat logging.
- New bot **[BOT]Stats** added. Commands still not written.
- Each user's statistics are stored to database.
- Daily statistics for registered users and bots/chatrooms.

2013-05-25
----------

- Restriction scripts loaded. Features are as listed:
    1. All nick names must start with alphanumeric characters.
    2. Only registered users are allowed to chat.
- Modify `string.find()` method with `string.match()` method.
- Comprehensive help for *[BOT]Info*.

2013-05-17
----------

- Chatroom commands have been added to right click menu.
- Fixed `invite` command bug.

2013-05-16
----------

- Right click commands are categorised according to each bot.
- Users can ask for specific menu-commands.

2013-05-11
----------

- Add `kick` and `invite` commands for chatrooms.
- Create moderator table for chatrooms.
- Kicking requires a master profile or user must be a moderator in room.

2013-05-09
----------

- Logging is optional.
- No logging for `#[QuizRoom]`.

2013-05-06
----------

- Minor bugfixes
- More errors added to FAQ.
- Newer and advanced chatrooms.


2013-05-04
----------

- [BOT]Info commands shall work from mainchat too.
- Help command separated for `ToArrival` and `ChatArrival` to avoid duplicate command.
- Report function added to `[BOT]Offliner` too.
- SQL table schema shared.

2013-04-29
----------

- Added a `Report` function.
- Changed some of the error reports to use `Report()`. The error codes are defined in database.

2013-04-25
----------

- `if`-`else` logic for the *switch* command corrected.

2013-04-15
----------

- A `string.find()` condition removed from if-else block. Will implement if spammers detected.

2013-04-13
----------

- Moderators; when newly added will have their profile changed too, if they are registered. Previously, the if-else logic failed to do so.

2013-04-09
----------

- Buy and sell implemented.
- Minor tweaks as listed below:
    1. Minimum length of message must be 20.
    2. Categories passed will be lowercase.
    3. Previously `readall` command repeated a particular message for all subsequent tables.
- Help file updated with new commands.
- Changed `INNER JOIN` syntax for `dl` command to `LEFT JOIN` to allow deletions for entries without magnets. Using the same to delete replies for Buy and Sell.
- Original users will be notified of any mesages/replies on their buy and sell thread.

2013-04-07
----------

- Create Buy and Sell feature
- Chage git configuration for `core.autocrlf`
- Use IST for dates in chagelogs.

2013-04-06
----------

- Shorten infobot.lua
  1. Change logic.
  2. Remove redundancy.

2013-04-05
----------

- Web-branch updated to use jQuery 1.9.1 now.

2013-04-04
----------

- Added SQL table schema for latest and chat stats.
- Created web-page and web-branch.

2013-04-03
----------

- Infobot updated

2013-04-02
----------

- First commit
- Readme added
- Offliner and Info BOT scripts added.
- File reporting script added.
