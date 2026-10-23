{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner;
    try {
      appRunner = await engineInitializer.initializeEngine({
        useColorEmoji: true,
      });
    } catch (e) {
      console.warn("Primary engine initialization failed, falling back to html renderer:", e);
      try {
        appRunner = await engineInitializer.initializeEngine({
          renderer: "html",
        });
      } catch (fallbackError) {
        console.error("Engine fallback initialization failed:", fallbackError);
        throw fallbackError;
      }
    }
    if (appRunner) {
      await appRunner.runApp();
    }
  }
});
