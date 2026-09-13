import type { Metadata, Viewport } from "next";

import { copyNo } from "@/features/signup/copy.no";

import "./globals.css";

export const metadata: Metadata = {
  title: copyNo.metadata.title,
  description: copyNo.metadata.description,
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#e4ebe0",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="nb" className="h-full">
      <body className="min-h-full">{children}</body>
    </html>
  );
}
