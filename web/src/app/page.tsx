import Image from "next/image";
import type { JSX } from "react";

import { copyNo, nextDeliverySentenceNo } from "@/features/signup/copy.no";
import { deriveNextMonday } from "@/features/signup/domain";
import { InterestForm } from "@/features/signup/interest-form";

export default function Page(): JSX.Element {
  const nextDelivery = deriveNextMonday(new Date());

  return (
    <main className="kk-page">
      <a className="kk-skip" href="#signup">
        {copyNo.a11y.skipToSignup}
      </a>
      <HeroSection />
      <FoodBoxImage />
      <OfferSection />
      <InterestForm nextDelivery={nextDelivery} />
      <NextDeliverySection delivery={nextDelivery} />
      <RecipeSection />
    </main>
  );
}

function HeroSection(): JSX.Element {
  return (
    <header className="kk-hero">
      <h1 className="kk-brand">{copyNo.hero.title}</h1>
      <p className="kk-lead">{copyNo.hero.lead}</p>
      <p className="kk-soft">{copyNo.hero.softLaunch}</p>
    </header>
  );
}

function FoodBoxImage(): JSX.Element {
  return (
    <figure className="kk-photo">
      <Image
        src="/ketokasse-hero.jpg"
        alt={copyNo.photo.alt}
        width={1280}
        height={720}
        priority
        sizes="(max-width: 430px) 100vw, 430px"
        className="kk-photo-img"
      />
    </figure>
  );
}

function OfferSection(): JSX.Element {
  return (
    <section className="kk-section kk-offer">
      <h2 className="kk-heading">{copyNo.offer.heading}</h2>
      <p className="kk-copy">{copyNo.offer.body}</p>
      <ul className="kk-group">
        {copyNo.offer.rows.map((row) => (
          <li className="kk-row" key={row}>
            {row}
          </li>
        ))}
      </ul>
    </section>
  );
}

function NextDeliverySection({
  delivery,
}: {
  delivery: ReturnType<typeof deriveNextMonday>;
}): JSX.Element {
  return (
    <section className="kk-section kk-next">
      <h2 className="kk-heading">{copyNo.nextDelivery.heading}</h2>
      <p className="kk-next-sentence">{nextDeliverySentenceNo(delivery)}</p>
      <p className="kk-copy">{copyNo.nextDelivery.recurrence}</p>
    </section>
  );
}

function RecipeSection(): JSX.Element {
  return (
    <section className="kk-section kk-recipe">
      <h2 className="kk-heading">{copyNo.recipe.heading}</h2>
      <p className="kk-copy">{copyNo.recipe.body}</p>
    </section>
  );
}
