import type { JSX } from "react";

import { landingNo } from "@/features/landing/landing";
import { LandingPage } from "@/features/landing/landing-page";

export default function Page(): JSX.Element {
  return <LandingPage landing={landingNo} />;
}
