// The extension collects no analytics (zero permissions, privacy-first), so the
// site's useTrack() becomes a no-op here. The reused component calls it freely.
export function useTrack() {
  return (_name: string, _props?: Record<string, string | number | boolean>) => {}
}
