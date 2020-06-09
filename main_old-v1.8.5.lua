--// Plugin: SBI [SpyaBeje Industries] - QF [QueenFinder]
--// SBI - QF


--Kept for history casses -- Also in case something in the main.lua isn't fully functional this si kept as a "reference".


local QF = {}; -- The plugin.
QF.botOwner = gkini.ReadString("SBI - QF", "BotOwner", "") -- Alt Owner.
QF.owner = "Scion Spy" -- Put Owner inside "Quotes"
QF.leave = {};
QF.logout = {};
QF.joinGroup = {};
QF.privMsg = {};
QF.version = "1.8.5"; -- Dev's to change.
local stop = false; -- We don't wont it to stop by default.. ([true] is essentially "off")
local last = last or ""; -- "Last" is the last spotting.
local active = false; -- QF.Toggle [/qf]


--[[
    QueenFinder Commands

    * Commands (Device side)
    ** /qf toggle -- Turns QueenFinder [ON|OFF]
    ** /qf setOwner <player name> -- Sets a secondary "owner" -- do not include quotes.
    ** /qf setBotOwner <player name> -- Sets the primary "Owner" -- do not include quotes.

    * Whisper Commands (/msg <spotterName> /<cmd>)
    ** /logout -- logs the spotter out. -- give 10-30 seconds.
    ** /qf -- Turns QueenFinder [ON|OFF]
    ** /setOwner <playerName> -- Sets a secondary "owner" -- do not include quotes.
    ** /group <leave|join|kick|invite> <playerName> -- all the group commands.
]]


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



-- Trim text
trim = function(txt)
	txt = txt or ""
	return (string.gsub(txt, "^%s*(.-)%s*$", "%1"))
end



function QF.toggle()
    if(active == true) then
        active = false;
        print("\127ffffffQueenFinder \127ffff00[Off]");
    else
        active = true;
        print("\127ffffffQueenFinder \127ffff00[On]");
    end;

    return active;
end;



function QF:CHAT_MSG_SECTORD_SECTOR(event, data)
    -- data = { msg=string }

    if(active == false) then return end;

    local args , rest = get_args(data.msg);
    local msg = "";
    if(args[2] == "Collector") then --Skip 3 args
        table.remove(args, 1); --["Artemis", "DenTek", "Kanneck", "Orun"];
        table.remove(args, 1); --"Collector";
        table.remove(args, 1); --"XD-1154u"; -- The ID.
        table.remove(args, 1); --"Jumped";
        table.remove(args, 1); --"to";


        msg = "QF: Queen located: "..table.concat(args, " "); --Tell us where they went!!
        if(msg == last) then -- if this spot data is also our last spot data.
            if(stop == true) then --and we're stopping
                return;
            end;
        end;
        last = msg;


        stop = true;
        Timer():SetTimeout(480000, function()
            stop = false;
        end);

        SendChat(msg, "SECTOR");
        SendChat(msg, "GROUP");
    end;
end;









--CHAT_MSG_GROUP
-- Navrout to location









function QF.joinGroup:CHAT_MSG_SERVER(event, data)
    --data = { msg=string }
    --print(data.msg) --Debugger.

    if(data.msg == "You have been invited to "..QF.botOwner.."'s group.") then
        if(GetNumGroupMembers() ~= 0) then
            local player = GetPlayerName(GetGroupOwnerID());
            if(player == GetPlayerName()) then --if Spotter is owner, send invite.
                Group.Invite(QF.botOwner);
                SendChat("I'm the leader of a group already. Here's an invite.","PRIVATE", QF.botOwner);
            end;

            SendChat("Spotter is already in a group, please contact "..player.." for an invite.", "PRIVATE", QF.botOwner)
        else
            Group.Join(QF.botOwner); --Join botOwner's group on invite.
        end;

    elseif(data.msg == "You have been invited to "..QF.owner.."'s group.") then
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
    end;

    if(active == false) then return end; --If [Off] stop right here.

    if(data.msg == "You are now a member of the group.") then
        SendChat("QueenFinder v."..QF.version.." broadcasting.", "GROUP");
    end; --Announce plugin activity on groupJoin.
end;


--lol = function(event, data)
    --SendChat(data.msg, "PRIVATE", "Rolflor");
--end;


function QF.privMsg:CHAT_MSG_PRIVATE(event, data)

    if(data.name ~= QF.botOwner) then -- If Whisper'r isn't BotOwner,
        if(data.name ~= QF.owner) then -- And not "Owner"
            return -- then Ignore.
        end;
    end;
    local args , rest = get_args(data.msg);




    if(args[1] == "/logout") then -- Well... Logout :P
        SendChat("QF: Logging out.", "PRIVATE", QF.botOwner);
        if(QF.owner ~= nil) then SendChat("QF: Logging out.", "PRIVATE", QF.owner) end;
        Logout() --> nil
    end;




    if(args[1] == "/group") then  -- ALL [/group] cmds
        table.remove(args, 1); -- Cmd "/group"

        if(args[1] == "leave") then
            --leave group. Triggers [GROUP_SELF_LEFT] event

            Group.Leave();
        elseif(args[1] == "join") then
            table.remove(args, 1); --SubCmd "join"
            table.remove(rest, 1);

            Group.Join(rest[1]);
        elseif(args[1] == "kick") then
            table.remove(args, 1); --SubCmd "kick"
            table.remove(rest, 1);

            Group.Kick(rest[1]);
        elseif(args[1] == "invite") then
            table.remove(args, 1); --SubCmd "invite";
            table.remove(rest, 1);

            Group.Invite(rest[1]);
        elseif(args[1] == "owner") then

            Group.Invite(QF.botOwner);
        end;
    end;




    if(args[1] == "/qf") then
        QF.toggle(); -- QueenFinder On/Off

        local toggled = "";
        if(active == true) then
            toggled = "QF: [ON]";
        else
            toggled = "QF: [OFF]";
        end;

        SendChat(toggled, "PRIVATE", QF.botOwner);
        if(QF.owner ~= nil) then SendChat(toggled, "PRIVATE", QF.owner) end;
    end;



    if(args[1] == "setOwner") then
        table.remove(args, 1) -- "setOwner";
        if(not args[1]) then print("\127ffffffPlease provide a new owner.") return end;

        local newOwner = table.concat(args, " ");
        QF.owner = newOwner;
        print("\127ffffffNew Owner = \127ffff00"..QF.owner);
    end;


end;



QF.commands = function(_, args)

    if(args[1] == "toggle") then
        QF.toggle();

    elseif(args[1] == "setOwner") then
        table.remove(args, 1) -- "setOwner";
        if(not args[1]) then print("\127ffffffPlease provide a new owner.") return end;

        local newOwner = table.concat(args, " ");
        QF.owner = newOwner;
        print("\127ffffffNew Owner = \127ffff00"..QF.owner);

    elseif(args[1] == "setBotOwner") then
        table.remove(args, 1) -- "setBotOwner";
        if(not args[1]) then print("\127ffffffPlease provide a new owner.") return end;

        local newBotOwner = table.concat(args, " ");
        QF.botOwner = newBotOwner;
        gkini.WriteString("SBI - QF", "BotOwner", QF.botOwner);
        print("\127ffffffNew Bot Owner = \127ffff00"..QF.botOwner);
    end;

end;



RegisterEvent(QF, "CHAT_MSG_SECTORD_SECTOR");
RegisterEvent(QF.joinGroup, "CHAT_MSG_SERVER");
RegisterEvent(QF.privMsg, "CHAT_MSG_PRIVATE");

RegisterUserCommand("qf", QF.commands);
