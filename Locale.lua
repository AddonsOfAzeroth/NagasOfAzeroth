-- Nagas of Azeroth by DinX: translations. Code uses English strings as keys: L["Text"].
local _, ns = ...
local NoA = ns.NoA

local NL = {}
NoA.translations = { nlNL = NL }

-- looked up at use time: "auto" follows Casters of Azeroth, else the game
NoA.L = setmetatable({}, {
	__index = function(_, key)
		local lang = NoA.db and NoA.db.language or "auto"
		if lang == "auto" then
			local c = NoA.Casters and NoA:Casters()
			lang = (c and c.db and c.db.language ~= "auto" and c.db.language) or (GetLocale and GetLocale() == "nlNL" and "nlNL") or "enUS"
		end
		local t = NoA.translations[lang]
		return t and t[key] or key
	end,
})

for k, v in pairs({
	-- layers
	["Plain"] = "Gewoon",
	["Shift"] = "Shift",
	["Ctrl"] = "Ctrl",
	["Alt"] = "Alt",
	-- plates
	["None"] = "Geen",
	["12 buttons (3 wide, 4 high)"] = "12 knoppen (3 breed, 4 hoog)",
	["6 buttons (2 wide, 3 high)"] = "6 knoppen (2 breed, 3 hoog)",
	["2 buttons (mouse 4 above 5)"] = "2 knoppen (muis 4 boven 5)",
	-- keysets
	["Keys"] = "Toetsen",
	["Standard (1 to =)"] = "Standaard (1 tot =)",
	["Numpad (Num1 to Num+)"] = "Numeriek klavier (Num1 tot Num+)",
	["Learned"] = "Aangeleerd",
	["Shift page"] = "Shift-pagina",
	["Off by default with numpad keys: with NumLock on, Windows turns Shift + a numpad key into another key, so WoW never sees it."] = "Standaard uit met numerieke toetsen: met NumLock aan maakt Windows van Shift + een numerieke toets een andere toets, dus WoW ziet hem nooit.",
	["Numpad keys: NumLock turns Shift + Num into other keys, so the Shift page is off. Use Ctrl and Alt in Hypershift."] = "Numerieke toetsen: NumLock maakt van Shift + Num andere toetsen, dus de Shift-pagina staat uit. Gebruik Ctrl en Alt in Hypershift.",
	-- learn mode
	["Learn my buttons"] = "Leer mijn knoppen",
	["Stop learning"] = "Stoppen met leren",
	["Skip"] = "Overslaan",
	["Learn mode: press each Naga button when it is asked for, without Shift, Ctrl or Alt. Keys stop here: nothing reaches your bars and nothing is cast. Click mouse buttons 4 and 5 over this window. Skip leaves a button empty, Esc cancels."] = "Leermodus: druk elke Naga-knop in als erom gevraagd wordt, zonder Shift, Ctrl of Alt. Toetsen stoppen hier: niets bereikt je balken en er wordt niets gecast. Klik muisknoppen 4 en 5 boven dit venster. Overslaan laat een knop leeg, Esc annuleert.",
	["Press button %d of %d."] = "Druk knop %d van %d in.",
	["press it now"] = "druk hem nu in",
	["skipped"] = "overgeslagen",
	["no key (skipped)"] = "geen toets (overgeslagen)",
	["Skip leaves a button empty. Esc cancels."] = "Overslaan laat een knop leeg. Esc annuleert.",
	["%s already arrived for button %d: press another key, or Skip."] = "%s kwam al aan voor knop %d: druk een andere toets in, of Overslaan.",
	["Nothing learned: your keys stay as they were."] = "Niets aangeleerd: je toetsen blijven zoals ze waren.",
	["Learned: %s."] = "Aangeleerd: %s.",
	-- settings
	["Side plate"] = "Zijplaat",
	["Pick the side plate on your Naga. The bar, its key bindings and the pages follow at once (after combat when you are fighting)."] = "Kies de zijplaat op je Naga. De balk, zijn sneltoetsen en de pagina's volgen meteen (na het gevecht als je aan het vechten bent).",
	["Naga bar"] = "Naga-balk",
	["A bar laid out like the plate: drag spells on it. The plate's keys press its buttons; a Blizzard binding of the same key waits while the Naga bar is on."] = "Een balk met dezelfde indeling als de plaat: sleep er spreuken op. De toetsen van de plaat drukken zijn knoppen in; een Blizzard-sneltoets op dezelfde toets wacht zolang de Naga-balk aan staat.",
	["Shift, Ctrl and Alt: extra pages"] = "Shift, Ctrl en Alt: extra pagina's",
	["Set Synapse's Hypershift to send Shift, Ctrl or Alt with the same key: each gives the bar another page of spells."] = "Laat Hypershift in Synapse Shift, Ctrl of Alt met dezelfde toets sturen: elk geeft de balk een andere pagina spreuken.",
	["Naga key in the rotation hint"] = "Naga-toets in de rotatiehint",
	["Casters of Azeroth: when the suggested spell is on the Naga bar, its key shows big under the hint (e.g. 7 or Shift 7) and that button glows."] = "Casters of Azeroth: staat de voorgestelde spreuk op de Naga-balk, dan staat zijn toets groot onder de hint (bv. 7 of Shift 7) en licht die knop op.",
	["Block bar-page switching on plate keys"] = "Wisselen van balkpagina blokkeren op plaattoetsen",
	["Blizzard binds Shift + 1 to 6 to its action bar pages. On the plate keys those go to the Naga bar's own pages, or do nothing; the rest of your keyboard keeps them."] = "Blizzard koppelt Shift + 1 tot 6 aan zijn actiebalkpagina's. Op de plaattoetsen gaan die naar de eigen pagina's van de Naga-balk, of doen ze niets; de rest van je toetsenbord houdt ze.",
	["The Naga bar uses action slots 37-48 (Blizzard's Right Bar 2) and, for Shift, Ctrl and Alt, the slots of Blizzard's bars 5, 6 and 7. /naga unlock to drag it."] = "De Naga-balk gebruikt actievakjes 37-48 (Blizzards Right Bar 2) en, voor Shift, Ctrl en Alt, de vakjes van Blizzards balken 5, 6 en 7. /naga unlock om hem te verslepen.",
	["Healers of Azeroth's hover keys (mouse over a frame + a plate key) follow its own plate. Set here, saved in Healers of Azeroth."] = "De hover-toetsen van Healers of Azeroth (muis op een frame + een plaattoets) volgen zijn eigen plaat. Hier ingesteld, bewaard in Healers of Azeroth.",
	["Same plate and keys for Healers"] = "Dezelfde plaat en toetsen voor Healers",
	["Your plate and keys here also set Healers of Azeroth's hover plate and keys (learned keys too), and the other way round."] = "Je plaat en toetsen hier zetten ook de hover-plaat en -toetsen van Healers of Azeroth (ook aangeleerde toetsen), en omgekeerd.",
	["Healers hover plate"] = "Hover-plaat van Healers",
	["Healers: also Shift, Ctrl and Alt + each plate key"] = "Healers: ook Shift, Ctrl en Alt + elke plaattoets",
	["Healers of Azeroth is not loaded. With it, the plate keys also cast heals while your mouse is on a group frame."] = "Healers of Azeroth is niet geladen. Daarmee casten de plaattoetsen ook heals zolang je muis op een groepsframe staat.",
	["Not in combat: try again after the fight."] = "Niet in een gevecht: probeer opnieuw na het gevecht.",
	["Naga map"] = "Naga-kaart",
	["Test screen"] = "Testscherm",
	["Also /naga map and /naga test. The map shows every key per layer; the test screen shows which key arrives."] = "Ook /naga map en /naga test. De kaart toont elke toets per laag; het testscherm toont welke toets aankomt.",
	["The Razer Naga settings have their own panel now: Esc > Options > AddOns > Razer Naga, or /naga."] = "De Razer Naga-instellingen hebben nu een eigen paneel: Esc > Opties > AddOns > Razer Naga, of /naga.",
	["Open the Razer Naga panel"] = "Razer Naga-paneel openen",
	-- slash
	["Frames locked."] = "Kaders vergrendeld.",
	["Frames unlocked: drag the Naga bar, type /naga lock when done."] = "Kaders ontgrendeld: versleep de Naga-balk, typ /naga lock als je klaar bent.",
	["/naga: settings. /naga map: the Naga map. /naga test: the test screen. /naga unlock: move the bar."] = "/naga: instellingen. /naga map: de Naga-kaart. /naga test: het testscherm. /naga unlock: de balk verplaatsen.",
	-- conflicts and paging
	["Razer Naga: %d keys also have a Blizzard key binding; the Naga bar wins while it is on. /naga test shows which."] = "Razer Naga: %d toetsen hebben ook een Blizzard-sneltoets; de Naga-balk wint zolang hij aan staat. /naga test toont welke.",
	["Razer Naga: %s switch your action bar page. Turn on \"Block bar-page switching on plate keys\" (/naga)."] = "Razer Naga: %s wisselen je actiebalkpagina. Zet \"Wisselen van balkpagina blokkeren op plaattoetsen\" aan (/naga).",
	["%s switches your action bar page"] = "%s wisselt je actiebalkpagina",
	["(blocked on the plate)"] = "(geblokkeerd op de plaat)",
	["nothing (bar paging blocked)"] = "niets (balkpagina geblokkeerd)",
	-- test screen
	["Razer Naga test"] = "Razer Naga-test",
	["Press your Naga buttons (with Shift, Ctrl or Alt for the other pages). Keys keep working while this is open; nothing is cast from here. Click mouse buttons 4 and 5 over this window. Red = bound twice. Esc closes."] = "Druk je Naga-knoppen in (met Shift, Ctrl of Alt voor de andere pagina's). Toetsen blijven gewoon werken zolang dit open staat; van hieruit wordt niets gecast. Klik muisknoppen 4 en 5 boven dit venster. Rood = dubbel gebonden. Esc sluit.",
	["Arrived: %s"] = "Aangekomen: %s",
	["Press a Naga button."] = "Druk een Naga-knop in.",
	["No side plate chosen: pick one in the Razer Naga settings (/naga)."] = "Geen zijplaat gekozen: kies er een in de Razer Naga-instellingen (/naga).",
	["Not on the plate:"] = "Niet op de plaat:",
	["empty slot"] = "leeg vakje",
	["nothing"] = "niets",
	["click %s"] = "klik %s",
	["also %s (the Naga bar wins while it is on)"] = "ook %s (de Naga-balk wint zolang hij aan staat)",
	["also %s"] = "ook %s",
	["The Naga test screen opens out of combat."] = "Het Naga-testscherm opent buiten een gevecht.",
	-- hub
	["Click: Naga map"] = "Klik: Naga-kaart",
	["Right-click: settings"] = "Rechtsklik: instellingen",
	["Shift-click: test screen"] = "Shift-klik: testscherm",
	-- map
	["Blue: Naga bar. Green: Healers hover key (mouse over a frame). Grey: Blizzard key binding. Red: clash."] = "Blauw: Naga-balk. Groen: hover-toets van Healers (muis op een frame). Grijs: Blizzard-sneltoets. Rood: botsing.",
	["Healers of Azeroth is not loaded: only the Naga bar and Blizzard's bindings show."] = "Healers of Azeroth is niet geladen: alleen de Naga-balk en Blizzards sneltoetsen staan erop.",
	["Healers of Azeroth's hover keys are off."] = "De hover-toetsen van Healers of Azeroth staan uit.",
}) do NL[k] = v end
