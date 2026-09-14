import type { Landing } from './model'

export const landingNo = {
  metadata: {
    title: 'KetoKasse',
    description:
      'Fem middager. To porsjoner. Levert mandag. Oppskriften i appen.',
  },
  brand: {
    name: 'ketokasse',
    logo: {
      src: '/visuals/logo.svg',
      alt: 'KetoKasse-maskot',
      width: 80,
      height: 80,
    },
  },
  appStore: {
    kind: 'pending',
    pillLabel: 'Last ned',
    storeKicker: 'Last ned i',
    storeName: 'App Store',
  },
  bands: [
    {
      kind: 'hero',
      id: 'hero',
      heading: 'Den gøyeste måten å spise keto på',
      visual: {
        src: '/visuals/hero.svg',
        alt: 'KetoKasse-maskot med mat og en telefon',
        width: 720,
        height: 560,
      },
    },
    {
      kind: 'story',
      id: 'dinners',
      heading: 'fem middager',
      body: 'To porsjoner. Du lager maten hjemme.',
      visual: {
        src: '/ketokasse-hero.jpg',
        alt: 'En KetoKasse med pakkede kjøttvarer og friske grønnsaker sett ovenfra.',
        width: 1280,
        height: 720,
      },
      tone: 'mint',
      visualSide: 'end',
    },
    {
      kind: 'story',
      id: 'monday',
      heading: 'mandagslevering',
      body: 'Kassen kommer mandag. Hver uke.',
      visual: {
        src: '/visuals/monday.svg',
        alt: 'En kasse levert ved døren på mandag',
        width: 640,
        height: 520,
      },
      tone: 'white',
      visualSide: 'start',
    },
    {
      kind: 'story',
      id: 'recipes',
      heading: 'oppskrift i appen',
      body: 'Ingen papir. Alt ligger i appen.',
      visual: {
        src: '/visuals/recipes.svg',
        alt: 'Telefon med en oppskrift i appen',
        width: 560,
        height: 640,
      },
      tone: 'peach',
      visualSide: 'end',
    },
    {
      kind: 'anywhere',
      id: 'anywhere',
      heading: 'keto hvor som helst',
      visual: {
        src: '/visuals/anywhere.svg',
        alt: 'Telefoner med ketooppskrifter',
        width: 980,
        height: 560,
      },
    },
  ],
} as const satisfies Landing
