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
      src: '/visuals/logo.png',
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
        src: '/visuals/mascot-hello.png',
        alt: 'KetoKasse-maskot som vinker',
        width: 1024,
        height: 1024,
      },
    },
    {
      kind: 'story',
      id: 'dinners',
      heading: 'fem middager',
      body: 'To porsjoner. Du lager maten hjemme.',
      visual: {
        src: '/visuals/mascot-deliver.png',
        alt: 'KetoKasse-maskot som leverer en kasse med grønnsaker og kjøtt',
        width: 1024,
        height: 1024,
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
        src: '/visuals/mascot-coach.png',
        alt: 'KetoKasse-maskot med ukeplan',
        width: 1024,
        height: 1024,
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
        src: '/visuals/mascot-think.png',
        alt: 'KetoKasse-maskot som tenker på middagen',
        width: 1024,
        height: 1024,
      },
      tone: 'peach',
      visualSide: 'end',
    },
    {
      kind: 'anywhere',
      id: 'anywhere',
      heading: 'keto hvor som helst',
      visual: {
        src: '/visuals/mascot-celebrate.png',
        alt: 'KetoKasse-maskot som feirer',
        width: 1024,
        height: 1024,
      },
    },
  ],
} as const satisfies Landing
