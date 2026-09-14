import Foundation

enum RecipeRegistry {
    static func recipe(forDishTitle title: String) -> Recipe? {
        byTitle[title]
    }

    static var all: [Recipe] { recipes }

    private static let recipes: [Recipe] = [
        squashLasagne,
        chiliTigerreker,
        cheeseburgerform,
        koteletter,
        kyllingpizza,
        meksikanskForm,
        tigerrekeTaco,
        fiskegrateng,
        lakseform,
        eggeform,
    ]

    private static let byTitle: [String: Recipe] = Dictionary(
        uniqueKeysWithValues: recipes.map { ($0.dishTitle, $0) }
    )
}

private enum Step {
    static func gather(_ dish: String, _ slug: String, _ title: String, symbol: String) -> RecipeStep {
        RecipeStep(
            id: "\(dish)/gather/\(slug)",
            kind: .gatherItem,
            title: title,
            body: "Finn den i kassen og kryss av.",
            points: 5,
            symbolName: symbol
        )
    }

    static func prep(_ dish: String, _ slug: String, _ title: String, _ body: String, symbol: String) -> RecipeStep {
        RecipeStep(
            id: "\(dish)/prep/\(slug)",
            kind: .prepTask,
            title: title,
            body: body,
            points: 10,
            symbolName: symbol
        )
    }

    static func cook(_ dish: String, _ slug: String, _ title: String, _ body: String, symbol: String) -> RecipeStep {
        RecipeStep(
            id: "\(dish)/cook/\(slug)",
            kind: .cookTask,
            title: title,
            body: body,
            points: 12,
            symbolName: symbol
        )
    }

    static func serve(_ dish: String, _ slug: String, _ title: String, _ body: String, symbol: String) -> RecipeStep {
        RecipeStep(
            id: "\(dish)/serve/\(slug)",
            kind: .serveNote,
            title: title,
            body: body,
            points: 8,
            symbolName: symbol
        )
    }
}

private extension RecipeRegistry {
    static let squashLasagne = Recipe(
        dishTitle: "Squash-lasagne",
        gather: [
            Step.gather("squash-lasagne", "kjottdeig", "Kjøttdeig", symbol: "fork.knife"),
            Step.gather("squash-lasagne", "squash", "Squash", symbol: "leaf.fill"),
            Step.gather("squash-lasagne", "lok", "Løk", symbol: "circle.grid.2x1"),
            Step.gather("squash-lasagne", "hvitlok", "Hvitløk", symbol: "allergens"),
            Step.gather("squash-lasagne", "tomatpure", "Tomatpuré", symbol: "archivebox.fill"),
            Step.gather("squash-lasagne", "kremflote", "Kremfløte", symbol: "drop.fill"),
            Step.gather("squash-lasagne", "ost", "Ost", symbol: "square.grid.3x3.fill"),
        ],
        prep: [
            Step.prep(
                "squash-lasagne", "salt-kjott", "Salt kjøttdeigen",
                "Strø salt over kjøttdeigen og la den ligge mens du gjør resten. Den blir saftigere og steker jevnere.",
                symbol: "sparkles"
            ),
            Step.prep(
                "squash-lasagne", "skjor-squash", "Skjær squash i tynne skiver",
                "Lag plater på et par millimeter. For tykke skiver gir vannete lag. For tynne brenner de i ovnen.",
                symbol: "square.split.1x2"
            ),
            Step.prep(
                "squash-lasagne", "hakk-lok", "Hakk løk og hvitløk",
                "Fin løk, enda finere hvitløk. Du skal kjenne dem i sausen, ikke bite i store biter.",
                symbol: "scissors"
            ),
        ],
        cook: [
            Step.cook(
                "squash-lasagne", "brun-kjott", "Brun kjøttet",
                "Stek kjøttdeig og løk til kjøttet er brunt og smuldrer. Rosa klumper og grå koking i eget vann betyr at pannen er for kald.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "squash-lasagne", "saus", "Lag den kremete sausen",
                "Rør inn tomatpuré til den mørkner et minutt. Hell i kremfløte og la det boble stille til sausen dekker skjeen.",
                symbol: "cup.and.saucer.fill"
            ),
            Step.cook(
                "squash-lasagne", "stek-lag", "Bygg lag og stek",
                "Veksle squash, kjøttsaus og ost. Ferdig når osten lager late bobler og squashen gir etter for en gaffel.",
                symbol: "square.stack.3d.up.fill"
            ),
        ],
        serve: [
            Step.serve(
                "squash-lasagne", "hvile", "La den hvile før du skjærer",
                "Fem minutter på benken. Da setter lagene seg, og du får ruter i stedet for suppe på tallerkenen.",
                symbol: "clock.fill"
            )
        ]
    )

    static let chiliTigerreker = Recipe(
        dishTitle: "Chilistekte tigerreker med brokkolimos",
        gather: [
            Step.gather("reker-brokkoli", "reker", "Tigerreker", symbol: "fish.fill"),
            Step.gather("reker-brokkoli", "brokkoli", "Brokkoli", symbol: "leaf.fill"),
            Step.gather("reker-brokkoli", "chili", "Chili", symbol: "flame.fill"),
            Step.gather("reker-brokkoli", "hvitlok", "Hvitløk", symbol: "allergens"),
            Step.gather("reker-brokkoli", "smor", "Smør", symbol: "oval.fill"),
            Step.gather("reker-brokkoli", "majones", "Majones", symbol: "circle.bottomhalf.filled"),
            Step.gather("reker-brokkoli", "lime", "Lime", symbol: "circle.fill"),
            Step.gather("reker-brokkoli", "koriander", "Koriander", symbol: "leaf"),
        ],
        prep: [
            Step.prep(
                "reker-brokkoli", "tork-reker", "Tørk rekene",
                "Klapp dem tørre med papir. Våte reker koker. Tørre reker får stekeskorpe.",
                symbol: "hand.raised.fill"
            ),
            Step.prep(
                "reker-brokkoli", "del-brokkoli", "Del brokkolien",
                "Små buketter koker jevnt. Stokken kan med, skåret i tynne skiver.",
                symbol: "leaf.fill"
            ),
            Step.prep(
                "reker-brokkoli", "hakk-chili", "Finhakk chili og hvitløk",
                "Ta ut chili-frøene hvis du vil ha varme uten bål. Hvitløk skal være fin, ikke knust til pasta.",
                symbol: "scissors"
            ),
        ],
        cook: [
            Step.cook(
                "reker-brokkoli", "mos", "Kok og mos brokkolien",
                "Kok til den er mør, ikke grå. Mos med smør til den er silkeaktig. Klumper er greit. Vannsuppe er det ikke.",
                symbol: "cup.and.saucer.fill"
            ),
            Step.cook(
                "reker-brokkoli", "stek-reker", "Stek rekene i chili-smør",
                "Høy varme, kort tid. De er ferdige når de er rosa og ringer seg som en C. En rett strek betyr at de har gått for lenge.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "reker-brokkoli", "lime-majones", "Rør lime-majones",
                "Majones, lime og et fnugg chili. Den skal være syrlig nok til å klippe gjennom det fete smøret.",
                symbol: "drop.fill"
            ),
        ],
        serve: [
            Step.serve(
                "reker-brokkoli", "topp", "Topp med koriander og lime",
                "Mos i bunnen, reker oppå, koriander og en limebåt. Spis med en gang. Reker venter dårlig.",
                symbol: "leaf.fill"
            )
        ]
    )

    static let cheeseburgerform = Recipe(
        dishTitle: "Cheeseburgerform",
        gather: [
            Step.gather("cheeseburger", "kjottdeig", "Kjøttdeig", symbol: "fork.knife"),
            Step.gather("cheeseburger", "bacon", "Bacon", symbol: "line.3.horizontal"),
            Step.gather("cheeseburger", "lok", "Løk", symbol: "circle.grid.2x1"),
            Step.gather("cheeseburger", "egg", "Egg", symbol: "oval.fill"),
            Step.gather("cheeseburger", "flote", "Fløte", symbol: "drop.fill"),
            Step.gather("cheeseburger", "tomatpure", "Tomatpuré", symbol: "archivebox.fill"),
            Step.gather("cheeseburger", "ost", "Ost", symbol: "square.grid.3x3.fill"),
            Step.gather("cheeseburger", "salat", "Salat", symbol: "leaf.fill"),
        ],
        prep: [
            Step.prep(
                "cheeseburger", "bacon", "Stek baconet sprøtt",
                "Stek til fettet er gjennomsiktig og kantene krøller. Legg det på papir. Fettet i pannen bruker du videre.",
                symbol: "flame.fill"
            ),
            Step.prep(
                "cheeseburger", "hakk-lok", "Hakk løken",
                "Små terninger. De skal smelte inn i kjøttet, ikke ligge som ringer.",
                symbol: "scissors"
            ),
            Step.prep(
                "cheeseburger", "ror-egg", "Rør egg i kjøttdeigen",
                "Ett egg binder formen så den ikke smuldrer når du øser. Ikke overarbeid deigen.",
                symbol: "oval.fill"
            ),
        ],
        cook: [
            Step.cook(
                "cheeseburger", "brun", "Brun kjøtt og løk",
                "Stek til kjøttet er brunt og løken er blank. Hvis det syder i grått vann, skru opp varmen og la det fordampe.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "cheeseburger", "saus", "Rør inn tomatpuré og fløte",
                "Tomatpuré først, så den får farge. Fløte etterpå. Sausen skal være tykk som burgerdressing, ikke suppe.",
                symbol: "cup.and.saucer.fill"
            ),
            Step.cook(
                "cheeseburger", "ost", "Dekk med ost og bacon",
                "Ost over det hele, bacon i biter oppå. Ferdig når osten er smeltet og har lysebrune flekker, ikke når den er svidd.",
                symbol: "square.grid.3x3.fill"
            ),
        ],
        serve: [
            Step.serve(
                "cheeseburger", "salat", "Salat på toppen, to minutter hvile",
                "Kald salat mot varm form. La formen stå to minutter så osten setter seg før du øser.",
                symbol: "leaf.fill"
            )
        ]
    )

    static let koteletter = Recipe(
        dishTitle: "Koteletter med blomkålmos",
        gather: [
            Step.gather("koteletter", "koteletter", "Koteletter", symbol: "fork.knife"),
            Step.gather("koteletter", "blomkal", "Blomkål", symbol: "cloud.fill"),
            Step.gather("koteletter", "lok", "Løk", symbol: "circle.grid.2x1"),
            Step.gather("koteletter", "flote", "Fløte", symbol: "drop.fill"),
            Step.gather("koteletter", "buljong", "Buljong", symbol: "cup.and.saucer.fill"),
            Step.gather("koteletter", "dijon", "Dijon", symbol: "circle.bottomhalf.filled"),
        ],
        prep: [
            Step.prep(
                "koteletter", "salt", "Salt kotelettene",
                "Salt begge sider og la dem ligge i romtemperatur et par minutter. Kalde koteletter steker ujevnt.",
                symbol: "sparkles"
            ),
            Step.prep(
                "koteletter", "blomkal", "Del blomkålen",
                "Små buketter koker fortere. Stokken med, skåret tynt. Alt skal bli mos.",
                symbol: "cloud.fill"
            ),
            Step.prep(
                "koteletter", "lok", "Hakk løken",
                "Fin løk til sausen. Den skal bli myk og søt, ikke sprø.",
                symbol: "scissors"
            ),
        ],
        cook: [
            Step.cook(
                "koteletter", "stek", "Stek kotelettene",
                "Middels-høy varme. Gyllen skorpe først, så lavere varme. De er ferdige når saften er klar og kjøttet har mistet den rå, blanke rosa midten. Litt rosa innerst er greit. Grått og tørt er for sent.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "koteletter", "mos", "Kok og mos blomkålen",
                "Kok mør, hell av vannet godt, mos med fløte. Moset skal holde en dump i skjeen. Renner det, har du for mye væske.",
                symbol: "cup.and.saucer.fill"
            ),
            Step.cook(
                "koteletter", "saus", "Rør Dijon-saus i pannen",
                "Løk, buljong og Dijon i stekefettet. Skrap bunnen. Sausen er klar når den er blank og kler baksiden av skjeen.",
                symbol: "drop.fill"
            ),
        ],
        serve: [
            Step.serve(
                "koteletter", "hvile", "Hvile under folie",
                "Tre minutter under løst folie. Saften går tilbake i kjøttet. Skjær nå, og den renner ut på brettet.",
                symbol: "clock.fill"
            )
        ]
    )

    static let kyllingpizza = Recipe(
        dishTitle: "Kyllingpizza med mozzarella og basilikum",
        gather: [
            Step.gather("kyllingpizza", "kylling", "Kylling", symbol: "bird.fill"),
            Step.gather("kyllingpizza", "ost", "Ost", symbol: "square.grid.3x3.fill"),
            Step.gather("kyllingpizza", "egg", "Egg", symbol: "oval.fill"),
            Step.gather("kyllingpizza", "tomatsaus", "Tomatsaus", symbol: "archivebox.fill"),
            Step.gather("kyllingpizza", "mozzarella", "Mozzarella", symbol: "circle.fill"),
            Step.gather("kyllingpizza", "oliven", "Oliven", symbol: "circle.grid.2x1"),
        ],
        prep: [
            Step.prep(
                "kyllingpizza", "riv", "Riv kyllingen",
                "Kokt eller restekylling rives i fine tråder. Store biter gjør bunnen ujevn.",
                symbol: "hand.raised.fill"
            ),
            Step.prep(
                "kyllingpizza", "deig", "Bland bunnen",
                "Kylling, ost og egg til en klistrete deig som holder sammen. For løs deig sprekker. For tørr blir den som knekkebrød.",
                symbol: "oval.fill"
            ),
            Step.prep(
                "kyllingpizza", "ovn", "Forvarm ovnen",
                "Høy varme, gjerne 220. En kald ovn gir slapp bunn.",
                symbol: "flame.fill"
            ),
        ],
        cook: [
            Step.cook(
                "kyllingpizza", "bunn", "Stek bunnen først",
                "Trykk deigen tynn på arket. Stek til kanten er gyllen og midten ikke lenger er bløt. Løft i kanten. Den skal holde.",
                symbol: "circle.grid.3x3.fill"
            ),
            Step.cook(
                "kyllingpizza", "topping", "Tomatsaus, mozzarella og oliven",
                "Tynt lag saus, ellers blir bunnen våt. Mozzarella i biter, oliven spredt. Ikke dekk hele kanten.",
                symbol: "leaf.fill"
            ),
            Step.cook(
                "kyllingpizza", "ferdig", "Stek til osten bobler",
                "Ferdig når mozzarellaen er smeltet med brune prikker og kanten er mørkere gyllen. Basilikum kommer etterpå, ellers svir den.",
                symbol: "flame.fill"
            ),
        ],
        serve: [
            Step.serve(
                "kyllingpizza", "hvile", "To minutter, så basilikum",
                "La pizzaen stå to minutter så osten setter seg. Så fersk basilikum oppå. Skjær nå, ikke rett fra ovnen.",
                symbol: "leaf.fill"
            )
        ]
    )

    static let meksikanskForm = Recipe(
        dishTitle: "Meksikansk form med kylling",
        gather: [
            Step.gather("meksikansk", "kylling", "Kylling", symbol: "bird.fill"),
            Step.gather("meksikansk", "paprika", "Paprika", symbol: "leaf.fill"),
            Step.gather("meksikansk", "creme", "Crème fraîche", symbol: "drop.fill"),
            Step.gather("meksikansk", "tacosaus", "Tacosaus", symbol: "archivebox.fill"),
            Step.gather("meksikansk", "cheddar", "Cheddar", symbol: "square.grid.3x3.fill"),
        ],
        prep: [
            Step.prep(
                "meksikansk", "strimle", "Strimle kyllingen",
                "Jeve strimler steker ferdig samtidig. Tykke klosser blir tørre utenpå og rå inni.",
                symbol: "scissors"
            ),
            Step.prep(
                "meksikansk", "paprika", "Skjær paprika i strimler",
                "Frøene ut. Strimler på tvers av lengden, så de blir myke uten å slappe helt.",
                symbol: "leaf.fill"
            ),
        ],
        cook: [
            Step.cook(
                "meksikansk", "kylling", "Stek kyllingen gjennom",
                "Ingen rosa kjerne, ingen blank rå saft. Skjær i den tykkeste biten. Hvitt og saftig er målet, ikke tørt og flisete.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "meksikansk", "paprika", "Stek paprikaen myk",
                "Den skal gi etter, men fortsatt ha farge. Svidde svarte kanter betyr at pannen var for tørr.",
                symbol: "leaf.fill"
            ),
            Step.cook(
                "meksikansk", "saus", "Rør tacosaus og crème fraîche",
                "Ta pannen av platetoppen før crème fraîche, ellers skiller den. Cheddar over. Ferdig når osten er smeltet og sausen bobler i kantene.",
                symbol: "cup.and.saucer.fill"
            ),
        ],
        serve: [
            Step.serve(
                "meksikansk", "hvile", "To minutter i formen",
                "La den stå. Sausen tykner, og du øser pene porsjoner i stedet for rennende taco.",
                symbol: "clock.fill"
            )
        ]
    )

    static let tigerrekeTaco = Recipe(
        dishTitle: "Tigerreke-taco",
        gather: [
            Step.gather("reketaco", "reker", "Tigerreker", symbol: "fish.fill"),
            Step.gather("reketaco", "isberg", "Isbergsalat", symbol: "leaf.fill"),
            Step.gather("reketaco", "avokado", "Avokado", symbol: "oval.fill"),
            Step.gather("reketaco", "lime", "Lime", symbol: "circle.fill"),
            Step.gather("reketaco", "chili", "Chili", symbol: "flame.fill"),
            Step.gather("reketaco", "koriander", "Koriander", symbol: "leaf"),
        ],
        prep: [
            Step.prep(
                "reketaco", "tork", "Tørk rekene",
                "Tørre reker steker. Våte reker koker og blir gummi.",
                symbol: "hand.raised.fill"
            ),
            Step.prep(
                "reketaco", "salat", "Skill salatblader til skall",
                "Hele, sprø blader. Skyll og tørk. Slappe blader holder ikke fylla.",
                symbol: "leaf.fill"
            ),
            Step.prep(
                "reketaco", "guacamole", "Mos avokado med lime",
                "Gaffel, ikke stavmikser. Klumper er tegn på ekte mos. Lime holder fargen og kutter det fete.",
                symbol: "circle.fill"
            ),
            Step.prep(
                "reketaco", "chili", "Finhakk chili",
                "Lite først. Du kan alltid legge på mer. Frøene er varmen.",
                symbol: "flame.fill"
            ),
        ],
        cook: [
            Step.cook(
                "reketaco", "stek", "Stek rekene rosa",
                "Høy varme, ett lag i pannen. Rosa og C-form er ferdig. Rett strek og tørr kant er overstekt. Ta dem av med en gang.",
                symbol: "flame.fill"
            )
        ],
        serve: [
            Step.serve(
                "reketaco", "fyll", "Fyll bladene og spis med en gang",
                "Mos, reker, chili, koriander. Ingen hvile her. Salatskallet blir slapt hvis det venter.",
                symbol: "leaf.fill"
            )
        ]
    )

    static let fiskegrateng = Recipe(
        dishTitle: "Fiskegrateng keto",
        gather: [
            Step.gather("fiskegrateng", "torsk", "Torsk", symbol: "fish.fill"),
            Step.gather("fiskegrateng", "blomkal", "Blomkål", symbol: "cloud.fill"),
            Step.gather("fiskegrateng", "flote", "Fløte", symbol: "drop.fill"),
            Step.gather("fiskegrateng", "egg", "Egg", symbol: "oval.fill"),
            Step.gather("fiskegrateng", "ost", "Ost", symbol: "square.grid.3x3.fill"),
        ],
        prep: [
            Step.prep(
                "fiskegrateng", "torsk", "Del torsken i biter",
                "Jeve biter på tommelstørrelse. Bein ut. For små biter går i oppløsning. For store blir rå inni.",
                symbol: "fish.fill"
            ),
            Step.prep(
                "fiskegrateng", "blomkal", "Kok blomkålen nesten mør",
                "Den skal gi etter, men fortsatt holde formen. Helt moset blomkål gir vannete grateng.",
                symbol: "cloud.fill"
            ),
            Step.prep(
                "fiskegrateng", "eggstokk", "Visp egg og fløte",
                "Sammen til en jevn stokk. Den skal se ut som tynn eggerøre, ikke som pisket krem.",
                symbol: "oval.fill"
            ),
        ],
        cook: [
            Step.cook(
                "fiskegrateng", "bygg", "Bygg formen",
                "Blomkål i bunnen, torsk oppå, eggeblanding over. Osten sist. Alt skal være dekket, ikke druknet.",
                symbol: "square.stack.3d.up.fill"
            ),
            Step.cook(
                "fiskegrateng", "stek", "Stek til midten er stiv",
                "Ferdig når midten ikke lenger skvulper og osten er gyllen. Rist formen forsiktig. En bølge betyr mer tid. En jevn dirring er nok.",
                symbol: "flame.fill"
            ),
        ],
        serve: [
            Step.serve(
                "fiskegrateng", "hvile", "Fem minutter før du øser",
                "Gratengen setter seg. Øs for tidlig, og den renner. Vent, og du får faste skjeer.",
                symbol: "clock.fill"
            )
        ]
    )

    static let lakseform = Recipe(
        dishTitle: "Kremet lakseform",
        gather: [
            Step.gather("lakseform", "laks", "Laks", symbol: "fish.fill"),
            Step.gather("lakseform", "brokkoli", "Brokkoli", symbol: "leaf.fill"),
            Step.gather("lakseform", "flote", "Fløte", symbol: "drop.fill"),
            Step.gather("lakseform", "kremost", "Kremost", symbol: "square.fill"),
            Step.gather("lakseform", "ost", "Ost", symbol: "square.grid.3x3.fill"),
            Step.gather("lakseform", "hvitlok", "Hvitløk", symbol: "allergens"),
        ],
        prep: [
            Step.prep(
                "lakseform", "laks", "Del laksen",
                "Store terninger. Skinnet av. Laksen skal holde bitene sine i formen, ikke bli postei.",
                symbol: "fish.fill"
            ),
            Step.prep(
                "lakseform", "brokkoli", "Del brokkolien",
                "Små buketter. De skal bli møre i ovnen uten å bli grå.",
                symbol: "leaf.fill"
            ),
            Step.prep(
                "lakseform", "hvitlok", "Press hvitløk",
                "Inn i kremsen senere. Fin, så den fordeler seg og ikke brenner som hele fedd.",
                symbol: "allergens"
            ),
        ],
        cook: [
            Step.cook(
                "lakseform", "laks", "Stek laksen til den flaker",
                "Den er ferdig når den går i flak med en gaffel og midten har mistet den rå, mørke blanke fargen. Matt og saftig. Tørr og hvit helt gjennom er for langt.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "lakseform", "saus", "Rør kremost, fløte og hvitløk",
                "Lav varme. Kremosten skal smelte inn, ikke koke i klumper. Sausen dekker skjeen når den er klar.",
                symbol: "drop.fill"
            ),
            Step.cook(
                "lakseform", "grateng", "Ost på toppen til den bobler",
                "Brokkoli og laks i sausen, ost over. Ferdig når osten bobler og brokkolien er mør med litt bitt.",
                symbol: "flame.fill"
            ),
        ],
        serve: [
            Step.serve(
                "lakseform", "hvile", "Tre minutter på benken",
                "Sausen tykner. Laksen hviler. Øs når det ikke lenger syder i kanten.",
                symbol: "clock.fill"
            )
        ]
    )

    static let eggeform = Recipe(
        dishTitle: "Eggeform med bacon og ost",
        gather: [
            Step.gather("eggeform", "egg", "Egg", symbol: "oval.fill"),
            Step.gather("eggeform", "bacon", "Bacon", symbol: "line.3.horizontal"),
            Step.gather("eggeform", "ost", "Ost", symbol: "square.grid.3x3.fill"),
            Step.gather("eggeform", "flote", "Fløte", symbol: "drop.fill"),
            Step.gather("eggeform", "lok", "Løk", symbol: "circle.grid.2x1"),
        ],
        prep: [
            Step.prep(
                "eggeform", "bacon", "Stek baconet",
                "Sprøtt nok til å knekke, ikke svidd. Ta det ut. Fettet blir smak i formen.",
                symbol: "flame.fill"
            ),
            Step.prep(
                "eggeform", "lok", "Hakk løken",
                "Små terninger som blir søte i baconfettet.",
                symbol: "scissors"
            ),
            Step.prep(
                "eggeform", "visp", "Visp egg og fløte",
                "Bare til det er jevnt. For mye visping gjør formen seig. Salt og pepper nå.",
                symbol: "oval.fill"
            ),
        ],
        cook: [
            Step.cook(
                "eggeform", "lok", "Surr løken myk",
                "I baconfettet til den er blank og søt. Brun er greit. Svart er bittert.",
                symbol: "flame.fill"
            ),
            Step.cook(
                "eggeform", "stek", "Hell i egg og stek til den er satt",
                "Løk og bacon i formen, egg over, ost på toppen. Ferdig når kantene er faste og midten fortsatt dirrer som gele. Helt stiv midt er tørr omelett.",
                symbol: "flame.fill"
            ),
        ],
        serve: [
            Step.serve(
                "eggeform", "hvile", "To minutter ut av ovnen",
                "Midten setter seg ferdig på ettervarmen. Skjær da, så får du rene biter.",
                symbol: "clock.fill"
            )
        ]
    )
}
