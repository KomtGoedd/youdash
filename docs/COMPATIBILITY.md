# Compatibility and known limits

## Intended OS range

The intended / reported compatibility range is **iOS 26.4–27.2**. This is experimental, not a claim that every release in the range has been tested. Versions below 26.4 and above 27.2 are outside this stated range. The observed device baseline below is the narrower evidence available.

## Demonstrated baseline

Actual YouTube 21.42.4 + YouMod 2.0.0, reporting 21.45.4, with the native YouTube player and this CarPlay module. UI and playback success were reported on a development iPhone running iOS 27.0.1 with several CarPlay display profiles. This is not certification for every head unit or every account.

The source targets iOS 17.0. A compilation target is not a promise that every target OS supports the required drawable CarPlay scene, entitlement, or vehicle behavior.

| Area | Behavior / limitation |
| --- | --- |
| Native phone scene | Preserved rather than replaced with a guessed initializer |
| Display sizes | Scale derives from the safe viewport; landscape supports split watch layout |
| CarPlay routing | Requires an authorized drawable window; templates alone cannot show arbitrary native views |
| Playback | Uses YouTube's existing engine; service behavior may vary by account/version |
| Reported version | 21.45.4 workaround; actual executable stays 21.42.4 |
| App updates | May rename private classes/selectors or alter layouts; compatibility is not automatic |
| Input | Native fields need to expose standard text-input APIs |
| Optional tweaks | Removed by default to reduce conflicts |
| Installation | Appropriate personal signing and capabilities required |

## Playback error 14

“Something went wrong. Refresh and try again later” is a generic playback failure. Reloading on every failure can create an interruption loop; it does not repair the cause. In the development session, restoring native request-signal/ad-coordinator methods did not fix it and introduced ads, so that experiment was reverted. Incognito also failed. Reporting version 21.45.4 was then observed to resolve playback on that device.

These are observations, not a guarantee. Upstream reports remain relevant:

- [YouMod #172 — playback stops during viewing](https://github.com/Tonwalter888/YouMod/issues/172)
- [YouMod #86 — playback-fix failures and error 14](https://github.com/Tonwalter888/YouMod/issues/86)
- [uYouEnhanced #903 — version-related workaround discussion](https://github.com/arichornlover/uYouEnhanced/issues/903)
- [YTLite #364 — mixed results across versions and configurations](https://github.com/dayanch96/YTLite/issues/364)

An AVPlayer-backend replacement was considered but **not included** in this baseline. It is not necessary to build this project.

## Report a useful issue

Include actual and reported versions, OS version, viewport dimensions, whether the issue affects phone/car/both, and exact reproduction steps. A cropped screenshot may help, but remove account names, notifications, location, and unrelated desktop content. Do not upload your provisioning profile, account state, raw app container, or unreviewed logs.
