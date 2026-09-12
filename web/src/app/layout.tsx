import type { Metadata } from "next";
import { Fraunces, Source_Sans_3 } from "next/font/google";

import { copyNo } from "@/features/signup/copy.no";

import "./globals.css";

const fraunces = Fraunces({
  subsets: ["latin", "latin-ext"],
  variable: "--font-fraunces",
  display: "swap",
});

const sourceSans = Source_Sans_3({
  subsets: ["latin", "latin-ext"],
  variable: "--font-source",
  display: "swap",
});

export const metadata: Metadata = {
  title: copyNo.metadata.title,
  description: copyNo.metadata.description,
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="nb"
      className={`${fraunces.variable} ${sourceSans.variable} h-full`}
    >
      <body className="min-h-full">{children}</body>
    </html>
  );
}
