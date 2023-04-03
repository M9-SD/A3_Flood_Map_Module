comment "
	Showcase: https://www.youtube.com/watch?v=GVmtg7y3gBw
	GitHub: https://github.com/M9-SD/A3_Flood_Map_Module
	License: https://github.com/M9-SD/A3_Flood_Map_Module/blob/main/LICENSE
	Discord: 
		- ZAM: https://discord.gg/bybqZj8Esu
		- SQF Archive: https://discord.gg/YnJWZGdVk8
	Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2949919975
";

0 = [] spawn {
	comment "uisleep 1.4;";
	waitUntil {isNull findDisplay 49};
	comment "findDisplay 49 closeDisplay 0;";
	uiNamespace setVariable ['highestPoint', nil];
	M9SD_fnc_getHighestPointOnMap = {
		private _hmSize = getTerrainInfo # 3;
		private _breatheTime = 0.01;
		highestPoint = [0, 0];
		highestPointHeight = 0;
		for "_grid_x" from 0 to worldSize do {
			for "_grid_y" from 0 to worldSize do {
				private _gridPos = [_grid_x, _grid_y];
				private _gridHeight = getTerrainHeight _gridPos;
				if (_gridHeight > highestPointHeight) then {
					highestPointHeight = _gridHeight;
					highestPoint = _gridPos;
					comment "sleep _breatheTime;";
				};
			};
		};
		comment "
			uiNamespace setVariable ['highestPoint', nil];
		";
		uiNamespace setVariable ['highestPoint', [highestPoint, highestPointHeight]];
		[highestPoint, highestPointHeight];
	};
	COMMENT "
	systemChat 'Standby - Analyzing terrain...';
	";
	COMMENT "
		call M9SD_fnc_getHighestPointOnMap;
	";
	COMMENT "
	[] spawn M9SD_fnc_getHighestPointOnMap;
	";
	COMMENT "waitUntil {!isNil {(uiNamespace getVariable ['highestPoint', nil])}};";
	COMMENT "
	systemChat 'Terrain analyzed.';
	";
	COMMENT "
	uiNamespace setVariable ['highestPoint', [[0,0], 0]];
	";
	private _fnc = (str {
		removeMissionEventHandler ["EachFrame", _thisEventHandler];
		{
			deleteMarker _x;
		} forEach floodMarkers;
		floodMarkers = nil;
		'flood markers deleted' remoteExec ['systemChat'];
	}) splitString '';
	_fnc deleteAt (count _fnc - 1); 
	_fnc deleteAt 0;
	missionNamespace setVariable ['M9SD_fnc_removeFloodMarkers', _fnc, true];
	private _fnc = (str {
		removeMissionEventHandler ["EachFrame", _thisEventHandler];
		floodMarkers = [];
		private _worldSize = worldSize;
		private _halfWorldSize = _worldSize / 2;
		private _mPos = [_halfWorldSize, _halfWorldSize, 0];
		private _mSize = [_halfWorldSize, _halfWorldSize];
		private _m1 = createMarker ["flood_marker_0", _mPos];
		floodMarkers pushback _m1;
		_m1 setMarkerSize _mSize;
		_m1 setMarkerShape "RECTANGLE";
		_m1 setMarkerColor "ColorWEST";
		private _m2 = createMarker ["flood_marker_1", _mPos];
		floodMarkers pushback _m2;
		_m2 setMarkerType "mil_warning";
		_m2 setMarkerText "FLOOD  IN  PROGRESS";
		_m2 setMarkerShape "ICON";
		_m2 setMarkerColor "ColorYellow";
		'flood markers created' remoteExec ['systemChat'];
	}) splitString '';
	_fnc deleteAt (count _fnc - 1); 
	_fnc deleteAt 0;
	missionNamespace setVariable ['M9SD_fnc_makeFloodMarkers', _fnc, true];
	M9SD_fnc_startFlooding = {
		M9SD_floodInProgress = true;
		publicVariable 'M9SD_floodInProgress';
		[[],{
			if (!hasInterface) exitWith {};
			if !(isnull findDisplay 312) then {
				["FLOODING STARTED", "<t align='center'><br/>The process may take a few minutes.<br/>Expect the server to lag until complete.<br/><br/>Open your map to view the progress.<br/><br/>", 30] call BIS_fnc_curatorHint;
			} else {
				hint "FLOODING STARTED\n\nThe process may take a few minutes.\nExpect the server to lag until complete.\n\nOpen your map to view the progress.";
			};
		}] remoteExec ['spawn'];
		comment "Old progress marker system (removed due to hypoxic server)";
		if (false) then {
			M9SD_floodMarkPos = [0, worldSize * 0.5];
			publicVariable 'M9SD_floodMarkPos';
			M9SD_floodLinePos = [[0, 0], [0, worldSize]];
			publicVariable 'M9SD_floodLinePos';
			{ 
				comment "-----------------------------------------------"; 
				if (!hasInterface) exitWith {}; 
				waitUntil { !isNil { player } && { !isNull player } }; 
				waitUntil { !isNull (findDisplay 46) }; 
				comment "-----------------------------------------------"; 
				M9SD_fnc_drawFloodMapMarkers =  
				{ 
					private _ctrl = _this select 0;
					_player = player; 
					private _floodMarkPos = missionnamespace getVariable ['M9SD_floodMarkPos',[]];
					private _floodLinePos = missionnamespace getVariable ['M9SD_floodLinePos',[]];
					if (count _floodMarkPos == 0) exitWith {}; 
					if (count _floodLinePos == 0) exitWith {}; 
					_ctrl drawLine [
						_floodLinePos # 0,
						_floodLinePos # 1,
						[0,1,0,1]
					];
					comment "
					_ctrl drawRectangle [
						[_floodMarkPos # 0, worldSize * 0.5],
						10,
						worldSize * 0.5,
						0,
						[0,1,0,1],
						'#(rgb,8,8,3)color(0,1,0,1)'
					];
					";
					_floodMarkPos2 = [(_floodMarkPos # 0) + 64, _floodMarkPos # 1];
					_ctrl drawIcon 
					[ 
						"\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa", 
						[0,1,0,1], 
						_floodMarkPos2, 
						25, 
						25, 
						0, 
						'  Flooding...', 
						2, 
						0.07, 
						"RobotoCondensedBold", 
						"right" 
					]; 
				}; 
				private _initMapMarkers_player = [] spawn  
				{ 
					waitUntil {(not (isNull (findDisplay 12 displayCtrl 51)))}; 
					if (!isNil "M9SD_EH_floodMapMarkers") then { 
						(findDisplay 12 displayCtrl 51) ctrlRemoveEventHandler ["Draw",M9SD_EH_floodMapMarkers]; 
					}; 
					M9SD_EH_floodMapMarkers = (findDisplay 12 displayCtrl 51) ctrlAddEventHandler ["Draw",  
					{ 
						if (visibleMap) then  
						{ 
							_this call M9SD_fnc_drawFloodMapMarkers; 
						}; 
					}];
				}; 
				private _initMapMarkers_zeus = [] spawn  
				{ 
					waitUntil {(not (isNull (findDisplay 312 displayCtrl 50)))}; 
					if (!isNil "M9SD_EH_floodMapMarkers2") then { 
						(findDisplay 312 displayCtrl 50) ctrlRemoveEventHandler ["Draw",M9SD_EH_floodMapMarkers2]; 
					}; 
					M9SD_EH_floodMapMarkers2 = (findDisplay 312 displayCtrl 50) ctrlAddEventHandler ["Draw",  
					{ 
						if (visibleMap) then  
						{ 
							_this call M9SD_fnc_drawFloodMapMarkers; 
						}; 
					}];
				};
				0 = [] spawn {
					waitUntil {sleep 0.5;!M9SD_floodInProgress};
					if (!isNil "M9SD_EH_floodMapMarkers2") then { 
						(findDisplay 312 displayCtrl 50) ctrlRemoveEventHandler ["Draw",M9SD_EH_floodMapMarkers2]; 
					}; 
					if (!isNil "M9SD_EH_floodMapMarkers") then { 
						(findDisplay 12 displayCtrl 51) ctrlRemoveEventHandler ["Draw",M9SD_EH_floodMapMarkers]; 
					}; 
				};
			} remoteExec ["BIS_fnc_spawn",0,"M9SD_JIP_floodProgressMarker"];
		}; 
		showChat true; 
		playSound ['addItemOk', true]; 
		playSound ['addItemOk', false];
		comment "[M9SD_floodMarkPos, M9SD_floodLinePos];";
		comment "0 = [] spawn {";
		comment "Display flood in progress map marker:";
		[[],{ 
			addMissionEventHandler ["EachFrame", (missionNamespace getVariable ['M9SD_fnc_makeFloodMarkers', '']) joinString '']; 
		}] remoteExec ['call', 2];
		[(profileNamespace getVariable ['M9SD_floodMeters', 0]) * -1,{
			0 = [] spawn {
				waitUntil {sleep 0.5;!M9SD_floodInProgress};
				[[],{ 
					addMissionEventHandler ["EachFrame", (missionNamespace getVariable ['M9SD_fnc_removeFloodMarkers', '']) joinString '']; 
				}] remoteExec ['call', 2];
			};
			chunkSizeStratis = 512;
			chunkSizeTanoa = 128;
			chunkSizeAltis = 256; comment "redo test";
			chunkSizeMalden = 512;
			chunkSizeLivonia = 512;
			chunkSize = switch (worldName) do {
				case "Stratis": {chunkSizeStratis};	
				case "Tanoa": {chunkSizeTanoa};	
				case "Altis": {chunkSizeAltis};	
				case "Malden": {chunkSizeMalden};	
				case "Livonia": {chunkSizeLivonia};	
				case "Enoch": {chunkSizeLivonia};	
				default {512};
			};
			breatheTime = 0.1; comment "give the server time to breathe (helps avoid client not responding kicks)";
			_floodScript = [] spawn 
			{
				_hmSize = getTerrainInfo # 3;
				_cellsize = getTerrainInfo # 2;
				_chunkCnt = (_hmSize / chunkSize) max 1;
				for "_chunkX" from 1 to _chunkCnt do {
					for "_chunkY" from 1 to _chunkCnt do {
						_positions = [];
						posOffX = (_chunkX - 1) * chunkSize;
						_posOffset = [posOffX, (_chunkY - 1) * chunkSize];
						comment "
						missionnamespace setVariable ['M9SD_floodMarkPos', _posOffset, true];
						missionnamespace setVariable ['M9SD_floodLinePos', [[posOffX, 0], [posOffX, worldSize]], true];
						";
						for "_i" from 0 to (_hmSize min chunkSize)-1 do {
							for "_j" from 0 to (_hmSize min chunkSize)-1 do {
								_pos = (_posOffset vectorAdd [_i, _j]) vectorMultiply _cellsize;
								_pos set [2, getTerrainHeight _pos - 10];
								_positions pushBack _pos;
								comment "
								missionnamespace setVariable ['M9SD_floodMarkPos', _pos, true];
								missionnamespace setVariable ['M9SD_floodLinePos', [[_pos # 0, 0], [_pos # 0, worldSize]], true];
								";
							};
						};
						setTerrainHeight [_positions, true];
						sleep breatheTime;
					};
				};
				["TaskSucceeded", ["", "Map area flooding complete."]] remoteExec ['BIS_fnc_showNotification'];
				[[],{
					if (!hasInterface) exitWith {};
					if !(isnull findDisplay 312) then {
						["FLOODING COMPLETED", "<t align='center'><br/>To reset the water level, restart the mission.<br/><br/>", 30] call BIS_fnc_curatorHint;
					} else {
						hint "FLOODING COMPLETED\n\nTo reset the water level, restart the mission.";
					};
				}] remoteExec ['spawn'];
				showChat true; 
				playSound ['addItemOk', true]; 
				playSound ['addItemOk', false];
			};
			waitUntil {sleep 0.1;scriptDone _floodScript};
			remoteExec ["","M9SD_JIP_floodProgressMarker"];
			missionnamespace setVariable ['M9SD_floodInProgress', false, true];
		}] remoteExec ['spawn', 2];
	};
	M9SD_fnc_moduleFloodMap = 
	{
		private _supportedMaps = ["Stratis", "Altis", "Malden", "VR"];
		private _unsupportedMaps = [];
		if (worldName in _unsupportedMaps) exitWith {
			if (isNull findDisplay 312) then {
				comment "?";
			} else {
				0 = [] spawn {
					private _result = ["The different terrain grid sizes ", worldName + " is not supported by this module.", true, true, findDisplay 312] call BIS_fnc_guiMessage;
				};
			};
		};
		if (missionnamespace getVariable ['M9SD_floodInProgress', false]) exitWith {
			if (isnull (findDisplay 312)) then {
				hint "\nFLOOD MAP MODULE\n\nA flood is currently in progress.\n\nPlease wait for the script to finish.\n\n";
			} else {
				["Flood Map Module", 
				"<t align='center'><br/><t size='1.1'>A flood is currently in progress.<br/><br/><t size='1'>Please wait for the script to finish.<br/><br/>"
				, 20] call BIS_fnc_curatorHint;
			};
			playSound ['3den_notificationwarning',true];
			playSound ['3den_notificationwarning',false];
			playSound ['additemfailed',true];
			playSound ['additemfailed',false];
		};
		playSound ['3den_notificationdefault',true];
		playSound ['3den_notificationdefault',false];
		if (isnull (findDisplay 312)) then {
			hint "\nFLOOD MAP MODULE\n\nDIRECTIONS:\n\nUse the slider to adjust the sea level in meters and then click OK. During execution of the script, the server will lag. The progress of the flood will be indicated on the map and updated in real-time. Server performance will return to normal when the flooding stops.\n\nWARNING:\n\nThis action cannot be undone.\nYou will need to restart the mission to reset the water level.\n\n";
		} else {
			[
				"Flood Map Module", 
				"<t align='center'><br/><t size='1.1'>DIRECTIONS:<br/><br/><t size='1'>Use the slider to adjust the sea level in meters and then click OK. During execution of the script, the server will lag. The progress of the flood will be indicated on the map and updated in real-time. Server performance will return to normal when the flooding stops.<br/><br/><t size='1.1'>WARNING:<br/><br/><t size='1'>This action cannot be undone.<br/>You will need to restart the mission to reset the water level.<br/><br/>",
				20
			] call BIS_fnc_curatorHint;
		};
		if (isNil 'M9SD_txtSizeStr') then 
		{
			M9SD_txtSizeStr = str (safeZoneH * 0.5);
			with uiNamespace do {M9SD_txtSizeStr = str (safeZoneH * 0.5);};
		};
		with uiNamespace do
		{
			disableSerialization;
			comment "
				M9SD_d_floodModule = (findDisplay 312) createDisplay 'RscDisplayEmpty';
			";
			createDialog 'RscDisplayEmpty';
			showchat true;
			M9SD_d_floodModule = findDisplay -1;
			_ctrl_quickscriptstitle = M9SD_d_floodModule ctrlCreate ["RscStructuredText", -1];
			_ctrl_quickscriptstitle ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.236 * safezoneH + safezoneY,0.165 * safezoneW,0.033 * safezoneH];
			_ctrl_quickscriptstitle ctrlSetStructuredText parseText ("<t shadow='0' size='" + str((safeZoneH * 0.5) * 1.5) + "' align='center'>Flood Map Module</t>");
			_ctrl_quickscriptstitle ctrlSetBackgroundColor [0.13,0.54,0.21,0.8];
			_ctrl_quickscriptstitle ctrlCommit 0;
			_ctrl_quickscriptstitle ctrlEnable false;
			_ctrl_qtxt = M9SD_d_floodModule ctrlCreate ["IGUIBack", -1];
			_ctrl_qtxt ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.28 * safezoneH + safezoneY,0.165 * safezoneW,0.11 * safezoneH];
			_ctrl_qtxt ctrlSetBackgroundColor [0,0,0,0.7];
			_ctrl_qtxt ctrlCommit 0;
			_ctrl_qtxt ctrlEnable false;
			_ctrl_entrrad = M9SD_d_floodModule ctrlCreate ["RscStructuredText", -1];
			_ctrl_entrrad ctrlSetPosition [0.427812 * safezoneW + safezoneX,0.291 * safezoneH + safezoneY,0.144375 * safezoneW,0.022 * safezoneH];
			_ctrl_entrrad ctrlSetStructuredText parseText ("<t size='" + M9SD_txtSizeStr + "' align='center'>Set sea level adjustment value in meters:</t>");
			_ctrl_entrrad ctrlSetBackgroundColor [0,0,0,0];
			_ctrl_entrrad ctrlCommit 0;
			M9SD_ctrl_floodSlider = M9SD_d_floodModule ctrlCreate ["RscXSliderH", -1];
			M9SD_ctrl_floodSlider ctrlSetPosition [0.427812 * safezoneW + safezoneX,0.324 * safezoneH + safezoneY,0.144375 * safezoneW,0.044 * safezoneH];
			M9SD_ctrl_floodSlider ctrlSetTextColor [1,1,1,1];
			M9SD_ctrl_floodSlider ctrlSetBackgroundColor [0,0,0,0.4];
			comment "M9SD_ctrl_floodSlider ctrlSetTooltip format ['Negative values will lower the sea level, thus revealing more terrain.\n\nPositive values will raise the sea level, thus flooding more terrain.\n\nThe highest point on %1 is %2 at %3m.', worldName, (uinamespace getvariable 'highestPoint') # 0, (uinamespace getvariable 'highestPoint') # 1];";
			M9SD_ctrl_floodSlider ctrlSetTooltip format ['Negative values will lower the sea level, thus revealing more terrain.\n\nPositive values will raise the sea level, thus flooding more terrain.\n'];
			M9SD_ctrl_floodSlider sliderSetRange [-64, 64];
			M9SD_ctrl_floodSlider sliderSetPosition (profileNamespace getVariable ['M9SD_floodMeters', 0]);
			M9SD_ctrl_floodSlider ctrlCommit 0;
			_ctrl_cancel = M9SD_d_floodModule ctrlCreate ["RscButtonMenu", -1];
			_ctrl_cancel ctrlSetPosition [0.536094 * safezoneW + safezoneX,0.401 * safezoneH + safezoneY,0.0464063 * safezoneW,0.022 * safezoneH];
			_ctrl_cancel ctrlSetStructuredText parseText ("<t size='" + M9SD_txtSizeStr + "' align='center'>CANCEL</t>");
			_ctrl_cancel ctrladdEventHandler ["ButtonClick", 
			{
				with uiNamespace do 
				{
					M9SD_d_floodModule closeDisplay 0;
				};
			}];
			_ctrl_cancel ctrlCommit 0;
			_ctrl_add = M9SD_d_floodModule ctrlCreate ["RscButtonMenu", -1];
			_ctrl_add ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.401 * safezoneH + safezoneY,0.0464063 * safezoneW,0.022 * safezoneH];
			_ctrl_add ctrlSetStructuredText parseText ("<t size='" + M9SD_txtSizeStr + "' align='center'>OK</t>");
			_ctrl_add ctrladdEventHandler ["ButtonClick", 
			{
				private _adjustmentValue = round(sliderPosition (uiNamespace getVariable 'M9SD_ctrl_floodSlider'));
				profileNamespace setVariable ['M9SD_floodMeters', _adjustmentValue];
				saveProfileNamespace;
				if ((_adjustmentValue == 0)) exitWith {}; 
				comment "systemChat str(_adjustmentValue)";
				_adjustmentValue spawn {
					private _sliderVal = _this;
					private _verbage = if (_sliderVal < 0) then {"lower"} else {"raise"};
					private _result = ["<t size='1.4'>WARNING:<br/><t size='1'>This action cannot be undone.<br/>It may take a few minutes to complete.<br/>During execution of the script, the server may lag.<br/>A mission restart will be required to reset the water level.<br/><br/><t size='1.4'>CONFIRMATION:<br/><t size='1'>Click YES if you wish to proceed.<br/>Click CANCEL to abort the script.<br/>", "Are you sure you want to " + _verbage + " the sea level by " + str(_sliderVal) + " meters?", 'Yes', true, findDisplay -1] call BIS_fnc_guiMessage;
					if (_result) then {
						comment  "The player is sure.";
						findDisplay -1 closeDisplay 0;
						0 = [] spawn M9SD_fnc_startFlooding;
					} else {
						comment "The player is not sure.";
					};
				};
			}];
			_ctrl_add ctrlCommit 0;
			_ctrl_qtxt2 = M9SD_d_floodModule ctrlCreate ["RscStructuredText", -1];
			_ctrl_qtxt2 ctrlSetPosition [0.469062 * safezoneW + safezoneX,0.401 * safezoneH + safezoneY,0.061875 * safezoneW,0.022 * safezoneH];
			_ctrl_qtxt2 ctrlSetBackgroundColor [0,0,0,0.8];
			_ctrl_qtxt2 ctrlCommit 0;
			while {uiSleep 0.01;!isNull (uiNamespace getVariable ['M9SD_d_floodModule',displayNull])} do {
				_ctrl_qtxt2 ctrlSetStructuredText parseText ("<t size='" + M9SD_txtSizeStr + "' align='center'>" + str(round((sliderPosition (uiNamespace getVariable 'M9SD_ctrl_floodSlider')))) + " m</t>");
				_ctrl_qtxt2 ctrlCommit 0;
			};
		};
	};
	[] spawn 
	{
		sleep 0.01;
		uiSleep 0.01;
		0 = [] spawn M9SD_fnc_moduleFloodMap;
	};
};
comment "deleteVehicle this";
comment "Determine if execution context is composition and delete the helipad.";
if ((!isNull (findDisplay 312)) && (!isNil 'this')) then {
	if (!isNull this) then {
		if (typeOf this == 'Land_HelipadEmpty_F') then {
			deleteVehicle this;
		};
	};
};