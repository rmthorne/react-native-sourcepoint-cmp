module.exports = {
  dependency: {
    platforms: {
      android: {
        sourceDir: '../android',
        packageImportPath:
          'import com.sourcepoint.reactnativecmp.ReactNativeCmpPackage;',
      },
      ios: {
        project: 'ReactNativeCmp.xcodeproj',
      },
    },
  },
};
