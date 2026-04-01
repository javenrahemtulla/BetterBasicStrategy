import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Better Basic Strategy",
  description: "Master blackjack basic strategy with a physically accurate 6-deck shoe trainer.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full bg-felt text-cream antialiased">{children}</body>
    </html>
  );
}
