--// Plugin: SBI [SpyaBeje Industries] - QF [QueenFinder]
--// SBI - QF

--// Description: A plugin for broadcasting collector jumps to (group) in order find a queen location. -- Does Not move it's self. Requires a Human pilot to navigate to sector "Jump Out". Afterwards bot/plug may be left unmonitered in a group.

--[[
--// ChangeLog
    v.1.9.1 -- Squished a couple of issue bugs and a spamming bug...
    v.1.9 -- Re-Write - +settings, +queensKilledCounter, +toggles
]]

--[[
--//ToDo:
    • Notify when cycle resets (Took too long to kill queen(s))
]]



local QF = {
    owner = "Scion Spy", -- Put Owner inside "Quotes". (Cannot be set via command.)
    version = "1.9.1", -- Dev's to change.
    KilledQueens = gkini.ReadString("SBI - QF", "KilledQueens", 0), --Amount of logged killed queens.

    _ = { --Toggles. -- true=[ON], false=[OFF].
        active = true; -- Plugin state.
        spotter = true; -- init state.
        joinMessage = false; -- "QueenFinder v.# boradcasting".
        guild = false; -- Send Spot data to (guild) channel.
        priv = nil; -- Send spot data to /msg "" -- priv = "Scion Spy" == /msg "Scion Spy"
        debug = false; -- Coder thing that will help identify what's where. (Does not cover ALL things.)
        debugE = nil; -- Coder thing that will help identify the Debuged Event.

        _last = last or ""; -- Prevents Spam when multi Jumps. DO NOT CHANGE
        _return = false; -- Prevents Spotter Spam! DO NOT CHANGE
    },

    coOwner = gkini.ReadString("SBI - QF", "CoOwner", nil), -- Secondary Owner. (May be set via command.)
    --name = "SBI - QF v."..this.version;

    white = "\127FFFFFF",
    yellow = "\127ffff00"
};


-- Trim text
trim = function(txt)
	txt = txt or ""
	return (string.gsub(txt, "^%s*(.-)%s*$", "%1"))
end

-- arg[1]
function get_args(str)
	local quotechar;
	local i=0;
	local args,argn,rest={},1,{};
	while true do
		local found,nexti,arg = string.find(str, '^"(.-)"%s*', i+1);
		if not found then found,nexti,arg = string.find(str, "^'(.-)'%s*", i+1) end;
		if not found then found,nexti,arg = string.find(str, "^(%S+)%s*", i+1) end;
		if not found then break end;
		table.insert(rest, string.sub(str, nexti+1));
		table.insert(args, arg);
		i = nexti;
	end;
	return args,rest;
end;


function ifNotPriv(msg, priv)
    if(not priv) then
        print("\127ffffff"..msg);
    else
        SendChat(msg, "PRIVATE", priv);
    end;
end;


--local args , rest = get_args(data.msg);
function QF.commands(_, msg, priv)
    --local cmd,rest = get_args(msg)

    local cmd = msg;
    if(cmd) then
        cmd[1] = string.lower(cmd[1]); --make "cmd" lowercase.
    else
        cmd = {""};
    end;

    if(QF._.debug)then
        print(QF.white.."> QF.commands || > Executing Commands. || > cmd[1] = "..cmd[1]);
    end;

    if(cmd[1] == "toggle")then
        local status = QF._.active;
        if(status == true)then
            QF._.active = false;
            print("\127ffffffQueenFinder \127ffff00[Off]");
        else
            QF._.active = true;
            print("\127ffffffQueenFinder \127ffff00[On]");
        end;

    elseif(cmd[1] == "on")then
        QF._.active = true;
        print("\127ffffffQueenFinder \127ffff00[On]");

    elseif(cmd[1] == "off")then
        QF._.active = false;
        print("\127ffffffQueenFinder \127ffff00[Off]");


    elseif(cmd[1] == "logout")then
        SendChat("QF: Logging out.", "PRIVATE", QF.owner);
        if(QF.coOwner ~= nil) then SendChat("QF: Logging out.", "PRIVATE", QF.coOwner) end;
        Logout() --> nil


    elseif(cmd[1] == "group")then
        table.remove(cmd, 1); -- Cmd "group"

        if(not cmd)then return ifNotPriv("QF: Group Help -- /group [leave, kick, invite, join] [player]", priv); end;

        if(cmd[1] == "leave") then
            --leave group. Triggers [GROUP_SELF_LEFT] event

            Group.Leave();

        elseif(cmd[1] == "join") then
            table.remove(cmd, 1); --SubCmd "join"
            local player = table.concat(cmd, " ");
            if(not player)then
                local msg = "Please provide a name to join!";
                if(not priv)then
                    return print(msg);
                else
                    return SendChat(msg, "PRIVATE", priv);
                end;
            else
                Group.Join(player);
            end;


        elseif(cmd[1] == "kick") then
            table.remove(cmd, 1); --SubCmd "kick"
            local player = table.concat(cmd, " ");
            if(not player)then
                local msg = "Please provide a name to kick!";
                if(not priv)then
                    return print(msg);
                else
                    return SendChat(msg, "PRIVATE", priv);
                end;
            else
                Group.Kick(player);
            end;


        elseif(cmd[1] == "invite") then
            table.remove(cmd, 1); --SubCmd "invite";
            local player = table.concat(cmd, " ");
            if(not player)then
                local msg = "Please provide a name to invite!";
                if(not priv)then
                    return print(msg);
                else
                    return SendChat(msg, "PRIVATE", priv);
                end;
            else
                Group.Invite(player);
            end;


        elseif(cmd[1] == "owner") then
            Group.Invite(QF.owner);

        end;


    elseif(cmd[1] == "settings")then
        table.remove(cmd, 1); --SubCmd "set"
        if(not cmd)then
            local msg = "Available settings: owner, coOwner, toggle <joinmessage, spotter, quild, priv>, setkills";
            if(not priv)then
                print(msg);
            else
                SendChat(msg, "PRIVATE", priv);
            end;
            return;
        end;
        cmd[1] = string.lower(cmd[1]); --make "cmd" lowercase.



        if(cmd[1] == "toggle")then
            table.remove(cmd, 1); --SubCmd "toggle"
            cmd[1] = string.lower(cmd[1]); --make "cmd" lowercase.

            if(cmd[1] == "joinmessage")then
                if(QF._.joinMessage)then QF._.joinMessage = false;
                else QF._.joinMessage=true;
                end;
                ifNotPriv("QF._.joinMessage toggled.", priv);

            elseif(cmd[1] == "spotter")then
                if(QF._.spotter)then QF._.spotter = false;
                else QF._.spotter=true;
                end;
                ifNotPriv("QF._.spotter toggled.", priv);

            elseif(cmd[1] == "guild")then
                if(QF._.guild)then QF._.guild = false;
                else QF._.guild=true;
                end;
                ifNotPriv("QF._.guild toggled.", priv);

            elseif(cmd[1] == "priv")then
                table.remove(cmd, 1); --SubCmd "priv";
                if(QF._.priv == nil)then
                    local player = table.concat(cmd, " ");
                    QF._.priv = player;
                else QF._.priv=nil;
                end;
                ifNotPriv("QF._.priv toggled.", priv);
            end;

        elseif(cmd[1] == "owner")then
            if(priv) then
                return SendChat("Please run this command via the Remote Device!", "PRIVATE", priv);
            end;

            table.remove(cmd, 1); --SubCmd "owner";
            if(not cmd[1]) then
                local msg = "\127ffffffPlease provide a new owner."
                if(not priv)then
                    return print(msg);
                else
                    return SendChat(msg, "PRIVATE", priv);
                end;
            else
                local player = table.concat(cmd, " ");
                QF.owner = player;
                print("\127ffffffNew Owner = \127ffff00"..QF.owner);
            end;


        elseif(cmd[1] == "coowner")then
            local OwnerCheck = false;
            if(priv) then
                if(priv ~= QF.owner) then
                    return SendChat("Only the Owner/Remote Device can set new Co-Owners.", "PRIVATE", priv);
                else
                    OwnerCheck = true;
                end;
            else
                OwnerCheck = true; --On RemoteDevice.
            end;
            if(not OwnerCheck)then return end; --OwnerCheck failed.

            table.remove(cmd, 1); --SubCmd "coowner";

            if(not cmd[1]) then
                local msg = "\127ffffffPlease provide a new owner."
                if(not priv)then
                    return print(msg);
                else
                    return SendChat(msg, "PRIVATE", priv);
                end;
            else
                local player = table.concat(cmd, " ");
                local msg = "\127ffffffNew Owner = \127ffff00"..QF.coOwner;
                QF.coOwner = player;
                gkini.WriteString("SBI - QF", "CoOwner", QF.coOwner);

                if(not priv)then
                    print(msg);
                else
                    SendChat(msg, "PRIVATE", priv);
                end;

                SendChat("You have been declared Co-Owner of this QueenFinder plugin. -- please /msg me and say \"/qf CONFIRM\" to finish the process.", "PRIVATE", QF.coOwner);
            end;


        elseif(cmd[1] == "setkills")then
            local OwnerCheck = false;
            if(priv) then
                if(priv ~= QF.owner) then
                    return SendChat("Only the Owner/Remote Device can set Killed Queens.", "PRIVATE", priv);
                else
                    OwnerCheck = true;
                end;
            else
                OwnerCheck = true; --On RemoteDevice.
            end;
            if(not OwnerCheck)then return end; --OwnerCheck failed.

            local msg = "";

            if(not cmd[2])then --No Number.
                msg = "Please inpute a number to set Killed Q's to."
                if(not priv)then
                    print(msg);
                else
                    SendChat(msg, "PRIVATE", priv);
                end;
                return;
            end;

            QF.KilledQueens = cmd[2];
            gkini.WriteString("SBI - QF", "KilledQueens", QF.KilledQueens);
            msg = "Killed Queens set to: "..QF.KilledQueens.." of Queens killed.";

            if(not priv)then
                print(msg);
            else
                SendChat(msg, "PRIVATE", priv);
            end;
        end;


    elseif(cmd[1] == "help")then
        help(priv);

    elseif(cmd[1] == "")then
        help();
    end;
end;--FN QF.commands


function help(priv)
    if(priv)then
        SendChat("Please check remote device for Help.", "PRIVATE", priv);
    end;

    print("");
    print(QF.yellow.."> QueenFinder v."..QF.version.." Created by: \"Scion Spy\"");
    print(QF.yellow.."> Most commands can be used via the '/msg \""..GetPlayerName().."\" <cmd>' usage.");
    print(QF.yellow.."> ");
    print(QF.yellow.."> /qf logout - Begins the [Logout] function");
    print(QF.yellow.."> /qf <toggle | on | off> - Turns the plugin on, off, or toggles it's state.");
    print(QF.yellow.."> /qf group <join | invite | kick | leave | owner> [\"User Name\"] -- 'owner' invites Owner.");
    print(QF.yellow.."> /qf settings <owner | coOwner> <\"User Name\"> -- Sets (Co)Owner. Allows Remote Access for most Commands.");
    print(QF.yellow.."> /qf settings setkills <Number> -- Sets the current queens to <Number> | Will persist! reset to 0 before Q'ing!");
    print(QF.yellow.."> /qf toggle <joinmessage | spotter> -- Toggles the Spotter and Group Join messages.");
    print(QF.yellow.."> /qf toggle <priv | guild> -- Sends messages to Guild/Private chats.\127o");
end;



function QF.privMsg(_, data)
    if(QF._.debug)then
        print(QF.white.."> QF.privMsg || > Read a private.");
    end;

    local txt = trim(data.msg)
    if string.byte(txt, 1) == iup.K_slash then --If message starts with "/" continue.

        if(QF._.debug)then
            print(QF.white.."> QF.privMsg || > Private is a command.");
        end;

        local cmd , rest = get_args(txt);
        if(cmd[1] == "/qf")then

            if(QF._.debug)then
                print(QF.white.."> QF.privMsg || > Running /qf commands || > cmd[2] = "..cmd[2]);
            end;

            if(cmd[2] == "invite")then
                SendChat("\""..data.name.."\" has requested an invite.... Sending...", "PRIVATE", QF.owner);
                return Group.Invite(data.name);
            else
                if(QF._.debug)then
                    print(QF.white.."> QF.privMsg || > cmd[2] ~= \"invite\" Checking Owner Status.");
                    print(QF.white.."> QF.privMsg || > Owner = \""..QF.owner.."\" || > CoOwner = \""..QF.coOwner.."\" || > Target = \""..data.name.."\"");
                end;

                if(data.name ~= QF.owner) then -- If Whisper'r isn't BotOwner,
                    if(data.name ~= QF.coOwner) then -- And not "Owner"
                        return -- then Ignore.
                    end;
                end;

                if(QF._.debug)then
                    print(QF.white.."> QF.privMsg || > Executing QF.commands(".._..", <<table>>, "..data.name..")");
                end;

                table.remove(cmd, 1); --Removing "/qf" from the list.
                QF.commands(_, cmd, data.name);
            end;
        end;
    end;

end;--FN QF.privMsg



function QF.joinGroup(event, data)
    if(not QF._.active)then return end;
    --data = { msg=string }
    --print(data.msg) --Debugger.

    if(data.msg == "You have been invited to "..QF.owner.."'s group.") then
        if(GetNumGroupMembers() ~= 0) then
            local player = GetPlayerName(GetGroupOwnerID());
            if(player == GetPlayerName()) then --if Spotter is owner, send invite.
                Group.Invite(QF.owner);
                SendChat("I'm the leader of a group already. Here's an invite.","PRIVATE", QF.owner);
            end;

            SendChat("Spotter is already in a group, please contact "..player.." for an invite.", "PRIVATE", QF.owner)
        else
            Group.Join(QF.owner); --Join owner's group on invite.
        end;

    elseif(data.msg == "You have been invited to "..QF.coOwner.."'s group.") then
        if(GetNumGroupMembers() ~= 0) then
            local player = GetPlayerName(GetGroupOwnerID());
            if(player == GetPlayerName()) then --if Spotter is owner, send invite.
                Group.Invite(QF.coOwner);
                SendChat("I'm the leader of a group already. Here's an invite.","PRIVATE", QF.coOwner);
            end;

            SendChat("Spotter is already in a group, please contact "..player.." for an invite.", "PRIVATE", QF.coOwner)
        else
            Group.Join(QF.coOwner); --Join coOwner's group on invite.
        end;
    end;

    if(QF._.joinMessage == false) then return end; --If [Off] stop right here.

    if(data.msg == "You are now a member of the group.") then
        SendChat("QueenFinder v."..QF.version.." broadcasting.", "GROUP");
    end; --Announce plugin activity on groupJoin.
end;



function QF.spotter(_, data) --Didn't re-write, works fine.
    -- data = { msg=string }
    QF.debugE("QF.spotter");
    QF.debug("Running Spotter.");

    if(QF._.active == false) then return end; --If spotter is offline, then STOP.
    QF.debug("Spotter Active.");

    local args , rest = get_args(data.msg);
    local msg = "";
    if(args[2] == "Collector") then --Skip 3 args
        table.remove(args, 1); --["Artemis", "DenTek", "Kanneck", "Orun"];
        table.remove(args, 1); --"Collector";
        table.remove(args, 1); --"XD-1154u"; -- The ID.
        table.remove(args, 1); --"Jumped";
        table.remove(args, 1); --"to";
        QF.debug("Collector Jumping....");

        msg = "QF: Queen located: "..table.concat(args, " "); --Tell us where they went!!
        QF.debug("Location: "..table.concat(args, " "));

        if(msg == QF._._last) then --If this Spot is also our Last Spot.
            QF.debug("Collectors jumping to previous location. || > Announce: \"Cycle Resseting.\"");
            msg = "QF: Cycle Reseting...."; --Tell everyone the Cycle just reset.
        end;

        if(msg ~= "QF: Cycle Reseting....")then --If we're not telling everyone the Cycle Reset,
            QF.debug("Collectors are jumping to a new location. || > Saving new spot data: \"QF._._last\"....");
            QF._._last = msg; -- Save our spot data as our most recent spot data.
            QF.debug("Spot Data Saved: \""..QF._._last.."\"");
        end;

        if(QF._._return)then QF.debug("\"QF._._return = true\" || STOP!"); return end;

        QF._._return = true; QF.debug("Setting: \"QF._._return\" set to \"true\"");
        QF.debug("Creating 8m timer to set \"QF._._return\" to \"false\"");
        Timer():SetTimeout(480000, function()
            QF._._return = false;
            QF.debugE("QF.spotter");
            QF.debug("Timer Ended: \"QF._._return\" set to \"false\"");
        end);

        QF.debug("Sending msg: \""..msg.."\"");
        QF.debug("> Sector");
        SendChat(msg, "SECTOR");
        QF.debug("> Group");
        SendChat(msg, "GROUP");
        if(QF._.guild)then QF.debug("> Guild"); SendChat(msg, "GUILD") end;
        if(QF._.priv)then QF.debug("> Private --> \""..QF._.priv.."\""); SendChat(msg, "PRIVATE", QF._.priv) end;
        QF.debug("> HUD:PrintSecondaryMsg");
        HUD:PrintSecondaryMsg(msg);

        QF.debug("> Event Executed Successfully.");
    end;
end;



function QF.counter(_, data) --CHAT_MSG_GROUP_NOTIFICATION
    --data = {msg=string, location=number(sectorID)};
    -- -- (group) [sectorID "number"] [TAG]<Name> msg(string)
    if(QF._.debug)then
        print(QF.white.."> Event: \"".._.."\"\n> Location: "..data.location.." || > Message: "..data.msg);
    end;

    if(not string.find(data.msg, "*Hive Queen"))then return end; -- The killed bot was not a Queen.

    QF.KilledQueens = QF.KilledQueens+1;
    gkini.WriteString("SBI - QF", "KilledQueens", QF.KilledQueens);
    local msg = "Queen Killed! New Count: "..QF.KilledQueens;
        SendChat(msg, "SECTOR");
        SendChat(msg, "GROUP");
        if(QF._.guild)then SendChat(msg, "GUILD") end;
        if(QF._.priv)then SendChat(msg, "PRIVATE", QF._.priv) end;
        HUD:PrintSecondaryMsg(msg);
end;




RegisterEvent(QF.privMsg, "CHAT_MSG_PRIVATE");
RegisterUserCommand("qf", QF.commands);


RegisterEvent(QF.joinGroup, "CHAT_MSG_SERVER");
RegisterEvent(QF.spotter, "CHAT_MSG_SECTORD_SECTOR");
RegisterEvent(QF.counter, "CHAT_MSG_GROUP_NOTIFICATION");



QF.debug = function(txt) -- QF.debug("");
    if(not QF._.debug)then return end; --Debugger is off. STOP.

    print(QF.white.."> "..QF._.debugE.." || "..txt);
end;
QF.debugE = function(txt) --QF.debugE("");
    if(not QF._.debug)then return end; --Debugger is off. STOP.

    QF._.debugE = txt; --Set the events Debug Event.
end;
