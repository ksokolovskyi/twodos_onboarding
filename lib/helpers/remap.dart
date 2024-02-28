extension Remap on double {
  double remap({
    required double fromLow,
    required double fromHigh,
    required double toLow,
    required double toHigh,
  }) {
    return (this - fromLow) * (toHigh - toLow) / (fromHigh - fromLow) + toLow;
  }
}
