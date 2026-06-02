/// Which of the three EVC apps a given build is.
///
/// All three share one codebase and one Supabase backend; this identifies the
/// role so shared code can branch on it (theming, routing, RLS-scoped queries).
enum EvcApp {
  rider('EVC Rider', 'Book a zero-emission cab in Dubai'),
  driver('EVC Driver', 'Drive electric. Earn smart.'),
  admin('EVC Admin', 'Run the network');

  const EvcApp(this.displayName, this.tagline);

  /// Human-facing app name, e.g. "EVC Rider".
  final String displayName;

  /// Short brand tagline shown on the landing screen.
  final String tagline;
}