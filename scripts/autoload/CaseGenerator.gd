extends Node
## CaseGenerator - Absurde retssager til Snoop Doggs Kaotiske Retssal

var _used_indices: Array = []

const CASES := [
	{
		"title": "Sag 420: Det Usynlige Kæledyr",
		"accusation": "Tiltalte beskyldes for at have stjålet naboens usynlige hund 'Hr. Lufthansen' og hævder, at hunden aldrig har eksisteret.",
		"context": "Naboerne har i årevis hørt hunden gø, men ingen kan beskrive dens udseende. Et tomt hundehalsbånd er eneste bevis.",
		"emoji": "🐕‍🦺"
	},
	{
		"title": "Sag 069: Måneskinscocktail-Bedrageri",
		"accusation": "Sagsøger hævder at have købt 3 liter 'ægte måneskinscocktail' fra tiltalte, der bare var postevand med sølvfarvet glimmer i.",
		"context": "Tiltalte insisterer på, at månen lyste på vandet i præcis 7 sekunder, og at det teknisk set gør det til måneskinscocktail.",
		"emoji": "🌙"
	},
	{
		"title": "Sag 187: Den Store Trivia-Konspiration",
		"accusation": "Tiltalte beskyldes for at have omskrevet ALLE spørgsmål i et Trivial Pursuit-spil til at have 'løg' som svar på alt.",
		"context": "Familien opdagede sabotagen først efter tre runder, da de bemærkede at svar på 'Hvad hedder Jordens måne?' var 'En stor løg'.",
		"emoji": "🧅"
	},
	{
		"title": "Sag 314: Den Forsvundne Tirsdag",
		"accusation": "Tiltalte hævder, at han har 'afskaffet tirsdage' for sin nabo og kræver kompensation for de tirsdage, naboens kat har spist.",
		"context": "Naboens kat sidder i vidneskranken og siger ingenting. Det betragtes som bevis.",
		"emoji": "📅"
	},
	{
		"title": "Sag 666: Gravitationssvindel",
		"accusation": "Sagsøger kræver erstatning fordi tiltalte 'solgte ham tyngdekraften' for 1.500 kr, og den virker stadig på ting han IKKE ejer.",
		"context": "Tiltaltes forsvar: Kontrakten specificerede ikke HVILKE ting tyngdekraften skulle virke på. Det er sagsøgers problem.",
		"emoji": "🌍"
	},
	{
		"title": "Sag 007: Uautoriseret Efterligning af En Bro",
		"accusation": "Tiltalte er anklaget for at stå fuldstændigt stille på en bro i 47 minutter og dermed 'forvirre trafikken om hans funktion'.",
		"context": "Tre cyklister forsøgte at køre over tiltalte, da de troede han var en bygningsdel.",
		"emoji": "🌉"
	},
	{
		"title": "Sag 42: Kvantemekanisk Kagesabotage",
		"accusation": "Tiltalte insisterer på, at kagen han bragte til fødselsdagen 'eksisterer i en superposition' og ikke kan ædes before observeret.",
		"context": "Kagen er forsvundet. Tiltalte siger den 'kollapset til ingenting' da alle kiggede på den.",
		"emoji": "🎂"
	},
	{
		"title": "Sag 101: Den Stjålne Morgenmad",
		"accusation": "Tiltalte er anklaget for at have spist sagsøgerens morgenmad, som tiltalte hævder var hans EGNE havregryn der 'gik i unionen' med sagsøgerens.",
		"context": "En havregrynsbaseret fagforening er oprettet som biintervenant i sagen.",
		"emoji": "🥣"
	},
	{
		"title": "Sag 77: Ulovlig Fremtidsspådom",
		"accusation": "Tiltalte sagde til sagsøger at 'det nok går', og da det IKKE gik, kræver sagsøger erstatning for fejlagtig fremtidsspådom.",
		"context": "Tiltalte forsvarer sig med, at 'det nok går' teknisk set stadig er muligt — bare ikke i den her dimension.",
		"emoji": "🔮"
	},
	{
		"title": "Sag 55: Den Fortryllede Parkbænk",
		"accusation": "Tiltalte sælger parkbænke som 'magiske troner der giver visdom'. Sagsøger sidder stadig på bænken efter 6 timer og venter på visdom.",
		"context": "Sagsøger viser billeder af sig selv på bænken. Han ser ikke klogere ud. Bænken er imødekommende men tavs.",
		"emoji": "🪑"
	},
	{
		"title": "Sag 13: Astronomisk Misvisning",
		"accusation": "Tiltalte solgte en stjerne med navn til sagsøger. Stjernen imploderede en uge efter købet. Sagsøger kræver refusion.",
		"context": "Stjernen var 4 milliarder år gammel. Tiltalte hævder det er sagsøgers fault for at stresse den med for meget opmærksomhed.",
		"emoji": "⭐"
	},
	{
		"title": "Sag 88: Spaghetti-Terrorisme",
		"accusation": "Tiltalte er anklaget for at have arrangeret spaghetti i naboshoppers indkøbsvogn i en form der ligner et ansigt. Naboen er traumatiseret.",
		"context": "Bevisbillede viser en spaghetti-formation der ligner Mona Lisa mere end et ansigt. Kunstnerisk ELLER kriminelt?",
		"emoji": "🍝"
	},
	{
		"title": "Sag 33: Midnatssangenes Tragedie",
		"accusation": "Tiltalte er anklaget for at synge 'Fadervor' til melodien af 'Baby Shark' ved naboens begravelse og hævder det var 'mere inklusivt'.",
		"context": "Tilhørerne lod sig rive med. Det hele endte med en doo-doo-doo-korus. Familien er delt.",
		"emoji": "🎵"
	},
	{
		"title": "Sag 19: Den Kvantificerede Venskabskrise",
		"accusation": "Sagsøger kræver erstatning fordi tiltalte sagde de var 'næsten venner', men nu kan ingen bestemme hvornår 'næsten' bliver til rigtige venner.",
		"context": "En matematiker er indkaldt som ekspertvidne for at kvantificere venskabsprocenter. Rapporten er 340 sider.",
		"emoji": "🤝"
	},
	{
		"title": "Sag 256: Wifi-Tyveri fra Fremtiden",
		"accusation": "Tiltalte hævder at naboens wifi-signal rejser baglæns i tid og stjæler hans båndbredde fra 2019. Han kræver erstatning for tabte Netflix-streams.",
		"context": "Tiltaltes router er fra 2019. Naboens er fra 2024. Tidspilen er under debat.",
		"emoji": "📡"
	},
	{
		"title": "Sag 11: Kattens Uautoriserede Karriere",
		"accusation": "Sagsøgers kat underskrev angiveligt en modelkontrakt mens ejeren sov. Katten nægter at kommentere. Bureauet vil have kontrakt-honorar.",
		"context": "Katten er mødt op til retsmødet og ser ekstremt professionel ud. Den blinker på mistænkelig vis.",
		"emoji": "😺"
	},
	{
		"title": "Sag 99: Det Flygtige Løfte om Pandekager",
		"accusation": "Tiltalte lovede pandekager 'snart' for 11 år siden. 'Snart' har aldrig fundet sted. Sagsøger er bitter og sulten.",
		"context": "Tiltaltes forsvar: Universet er 13,8 milliarder år gammelt. 11 år ER snart i kosmisk skala.",
		"emoji": "🥞"
	},
	{
		"title": "Sag 22: Ulovlig Vejrtrækning i Fredet Zone",
		"accusation": "Tiltalte indåndede ilt i en zone der er 'reserveret til planter' ifølge et skilt tiltalte selv satte op. Nu sagsøger han sig selv.",
		"context": "Tiltalte er sagsøger OG tiltalte. Han er mødt op i to sæt tøj. Dommeren er forvirret.",
		"emoji": "🌿"
	},
	{
		"title": "Sag 555: Den Filosofiske Kaffekontrakt",
		"accusation": "Sagsøger bestilte 'kaffe med mening' på en café. Barista serverede espresso med et Nietzsche-citat. Sagsøger fandt ingen mening.",
		"context": "Citatet var 'Gud er død'. Sagsøger er ateist og kræver refusion da kaffen hverken gav mening eller wakened him up.",
		"emoji": "☕"
	},
	{
		"title": "Sag 777: Helikopterspillet Uden Helikopter",
		"accusation": "Tiltalte solgte billetter til 'helikoptertur over København' for 200 kr. Turen foregik ved at tiltalte snurrede rundt med armene ud.",
		"context": "Kunderne var FAKTISK imponeret. En anmelder gav det 4 stjerner på TripAdvisor. Tiltalte føler sig forfølget.",
		"emoji": "🚁"
	},
	{
		"title": "Sag 3: Den Omtvistede Regn",
		"accusation": "Naboen er anklaget for at 'have sendt regn' over til sagsøgers havefest med sin nye vandpistol. Det regnede 40mm den dag.",
		"context": "Meteorologisk rapport viser at lavtryk kom fra Atlanten. Naboen har en super soaker 3000. Tilfælde?",
		"emoji": "🌧️"
	},
	{
		"title": "Sag 404: Den Manglende Sag",
		"accusation": "Tiltalte er anklaget for at have anklaget sagsøger for noget som ingen kan huske. Selve anklagen er forsvundet. Dette er retssagen om retssagen.",
		"context": "Ingen ved præcist hvad der skete. Alle er her alligevel. Snoop Dogg er forvirret men fascineret.",
		"emoji": "❓"
	},
	{
		"title": "Sag 808: Beatbox-Sabotage",
		"accusation": "Tiltalte er anklaget for at have erstattet naboens morgenalarm med en beatbox-version af 'It's a Small World'. Naboen er nu uhelbredelig.",
		"context": "Offeret viser tegn på spontan beatboxing i hverdagen. Tiltalte har solide rytmiske beviser for sin uskyld.",
		"emoji": "🥁"
	},
	{
		"title": "Sag 1: Verdens Første Retssag Om En Retssag",
		"accusation": "Dette er en retssag for at afgøre om det er lovligt at holde en retssag om dette. Den er selvreferencerende og muligvis illegal.",
		"context": "Logikken i sagen kollapser allerede ved åbningserklæringen. Alle advokater er kommet hjem fra sygeorlov.",
		"emoji": "♾️"
	},
]

func get_random_case() -> Dictionary:
	if _used_indices.size() >= CASES.size():
		_used_indices.clear()
	
	var available := []
	for i in range(CASES.size()):
		if not i in _used_indices:
			available.append(i)
	
	available.shuffle()
	var idx := available[0]
	_used_indices.append(idx)
	
	var case_data := CASES[idx].duplicate()
	case_data["id"] = idx
	return case_data

func get_case_summary(case_data: Dictionary) -> String:
	return "%s\n\n%s\n\n%s" % [
		case_data.get("title", ""),
		case_data.get("accusation", ""),
		case_data.get("context", "")
	]
