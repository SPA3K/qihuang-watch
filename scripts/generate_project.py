#!/usr/bin/env python3
"""
Generate Xcode project files for QiHuangPulse.
No xcodegen needed - creates .xcodeproj directly.
"""
import os
import json
import uuid
import hashlib

# ═══════════════════════════════════════════
# Utility
# ═══════════════════════════════════════════

def gen_id(name=""):
    """Generate a deterministic 24-char hex ID for pbxproj."""
    h = hashlib.md5((name + str(uuid.uuid4())).encode()).hexdigest()[:24]
    return h.upper()

# ═══════════════════════════════════════════
# Collect source files
# ═══════════════════════════════════════════

def collect_swift_files(*dirs):
    """Recursively collect .swift files from directories."""
    files = []
    for d in dirs:
        if not os.path.isdir(d):
            continue
        for root, _, filenames in os.walk(d):
            for f in sorted(filenames):
                if f.endswith('.swift'):
                    full = os.path.join(root, f)
                    rel = os.path.relpath(full, '.')
                    files.append(rel)
    return files

# ═══════════════════════════════════════════
# Generate pbxproj
# ═══════════════════════════════════════════

def generate_pbxproj():
    """Generate the project.pbxproj content."""
    
    # File groups
    iphone_files = collect_swift_files('iPhone')
    shared_models = collect_swift_files('Sources/Models')
    shared_services = collect_swift_files('Sources/Services')
    shared_viewmodels = collect_swift_files('Sources/ViewModels')
    shared_config = ['Sources/Config/Secrets.swift.example']
    watch_app = collect_swift_files('Sources/App')
    watch_views = collect_swift_files('Sources/Views')
    
    all_sources = {
        'iphone': iphone_files,
        'shared': shared_models + shared_services + shared_viewmodels + shared_config,
        'watch_app': watch_app,
        'watch_views': watch_views,
    }
    
    # Generate IDs for everything
    ids = {}
    for group_name, files in all_sources.items():
        ids[group_name] = {}
        for f in files:
            ids[group_name][f] = {
                'file_ref': gen_id(f'fileref_{f}'),
                'build_file': gen_id(f'buildfile_{f}'),
            }
    
    # Group IDs
    ids['root_group'] = gen_id('root_group')
    ids['iphone_group'] = gen_id('iphone_group')
    ids['shared_group'] = gen_id('shared_group')
    ids['watch_group'] = gen_id('watch_group')
    ids['watch_app_group'] = gen_id('watch_app_group')
    ids['watch_views_group'] = gen_id('watch_views_group')
    ids['products_group'] = gen_id('products_group')
    
    # Target IDs
    ids['iphone_target'] = gen_id('iphone_target')
    ids['watch_target'] = gen_id('watch_target')
    ids['iphone_product'] = gen_id('iphone_product_ref')
    ids['watch_product'] = gen_id('watch_product_ref')
    ids['iphone_build_config_list'] = gen_id('iphone_bcl')
    ids['watch_build_config_list'] = gen_id('watch_bcl')
    ids['project_config_list'] = gen_id('proj_bcl')
    
    # Build configurations
    ids['iphone_debug'] = gen_id('iphone_debug')
    ids['iphone_release'] = gen_id('iphone_release')
    ids['watch_debug'] = gen_id('watch_debug')
    ids['watch_release'] = gen_id('watch_release')
    ids['project_debug'] = gen_id('project_debug')
    ids['project_release'] = gen_id('project_release')
    
    # Framework build phase IDs
    ids['iphone_fw'] = gen_id('iphone_fw')
    ids['watch_fw'] = gen_id('watch_fw')
    ids['iphone_sources_phase'] = gen_id('iphone_sources_phase')
    ids['iphone_resources_phase'] = gen_id('iphone_resources_phase')
    ids['watch_sources_phase'] = gen_id('watch_sources_phase')
    ids['watch_resources_phase'] = gen_id('watch_resources_phase')
    
    # Target dependency
    ids['target_dep'] = gen_id('target_dep')
    ids['container_proxy'] = gen_id('container_proxy')
    
    lines = []
    def w(s=""):
        lines.append(s)
    
    w('// !$*UTF8*$!')
    w('{')
    w('\tarchiveVersion = 1;')
    w('\tclasses = {')
    w('\t};')
    w('\tobjectVersion = 56;')
    w('\tobjects = {')
    w('')
    
    # ─── PBXBuildFile ───
    w('/* Begin PBXBuildFile section */')
    for group_name, files in all_sources.items():
        for f in files:
            ref = ids[group_name][f]['file_ref']
            bid = ids[group_name][f]['build_file']
            w(f'\t\t{bid} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {os.path.basename(f)} */; }};')
    w('/* End PBXBuildFile section */')
    w('')
    
    # ─── PBXFileReference ───
    w('/* Begin PBXFileReference section */')
    for group_name, files in all_sources.items():
        for f in files:
            ref = ids[group_name][f]['file_ref']
            w(f'\t\t{ref} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {os.path.basename(f)}; sourceTree = "<group>"; }};')
    w(f'\t\t{ids["iphone_product"]} /* QiHuangPulse.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = QiHuangPulse.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    w(f'\t\t{ids["watch_product"]} /* QiHuangWatch.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = QiHuangWatch.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    w('/* End PBXFileReference section */')
    w('')
    
    # ─── PBXFrameworksBuildPhase ───
    w('/* Begin PBXFrameworksBuildPhase section */')
    w(f'\t\t{ids["iphone_fw"]} /* Frameworks */ = {{')
    w('\t\t\tisa = PBXFrameworksBuildPhase;')
    w('\t\t\tbuildActionMask = 2147483647;')
    w('\t\t\tfiles = (')
    w('\t\t\t);')
    w('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    w('\t\t};')
    w(f'\t\t{ids["watch_fw"]} /* Frameworks */ = {{')
    w('\t\t\tisa = PBXFrameworksBuildPhase;')
    w('\t\t\tbuildActionMask = 2147483647;')
    w('\t\t\tfiles = (')
    w('\t\t\t);')
    w('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    w('\t\t};')
    w('/* End PBXFrameworksBuildPhase section */')
    w('')
    
    # ─── PBXGroup ───
    w('/* Begin PBXGroup section */')
    
    # Root group
    w(f'\t\t{ids["root_group"]} = {{')
    w('\t\t\tisa = PBXGroup;')
    w('\t\t\tchildren = (')
    w(f'\t\t\t\t{ids["iphone_group"]} /* iPhone */,')
    w(f'\t\t\t\t{ids["shared_group"]} /* Sources */,')
    w(f'\t\t\t\t{ids["watch_group"]} /* Watch */,')
    w(f'\t\t\t\t{ids["products_group"]} /* Products */,')
    w('\t\t\t);')
    w('\t\t\tsourceTree = "<group>";')
    w('\t\t};')
    
    # iPhone group
    w(f'\t\t{ids["iphone_group"]} /* iPhone */ = {{')
    w('\t\t\tisa = PBXGroup;')
    w('\t\t\tchildren = (')
    for f in iphone_files:
        w(f'\t\t\t\t{ids["iphone"][f]["file_ref"]} /* {os.path.basename(f)} */,')
    w('\t\t\t);')
    w('\t\t\tpath = iPhone;')
    w('\t\t\tsourceTree = "<group>";')
    w('\t\t};')
    
    # Shared group
    w(f'\t\t{ids["shared_group"]} /* Sources */ = {{')
    w('\t\t\tisa = PBXGroup;')
    w('\t\t\tchildren = (')
    for f in shared_models + shared_services + shared_viewmodels + shared_config:
        w(f'\t\t\t\t{ids["shared"][f]["file_ref"]} /* {os.path.basename(f)} */,')
    w('\t\t\t);')
    w('\t\t\tpath = Sources;')
    w('\t\t\tsourceTree = "<group>";')
    w('\t\t};')
    
    # Watch group
    w(f'\t\t{ids["watch_group"]} /* Watch */ = {{')
    w('\t\t\tisa = PBXGroup;')
    w('\t\t\tchildren = (')
    for f in watch_app:
        w(f'\t\t\t\t{ids["watch_app"][f]["file_ref"]} /* {os.path.basename(f)} */,')
    for f in watch_views:
        w(f'\t\t\t\t{ids["watch_views"][f]["file_ref"]} /* {os.path.basename(f)} */,')
    w('\t\t\t);')
    w('\t\t\tpath = Sources;')
    w('\t\t\tsourceTree = "<group>";')
    w('\t\t};')
    
    # Products group
    w(f'\t\t{ids["products_group"]} /* Products */ = {{')
    w('\t\t\tisa = PBXGroup;')
    w('\t\t\tchildren = (')
    w(f'\t\t\t\t{ids["iphone_product"]} /* QiHuangPulse.app */,')
    w(f'\t\t\t\t{ids["watch_product"]} /* QiHuangWatch.app */,')
    w('\t\t\t);')
    w('\t\t\tname = Products;')
    w('\t\t\tsourceTree = "<group>";')
    w('\t\t};')
    
    w('/* End PBXGroup section */')
    w('')
    
    # ─── PBXNativeTarget ───
    w('/* Begin PBXNativeTarget section */')
    
    # iPhone target
    w(f'\t\t{ids["iphone_target"]} /* QiHuangPulse */ = {{')
    w('\t\t\tisa = PBXNativeTarget;')
    w(f'\t\t\tbuildConfigurationList = {ids["iphone_build_config_list"]};')
    w(f'\t\t\tbuildPhases = (')
    w(f'\t\t\t\t{ids["iphone_sources_phase"]} /* Sources */,')
    w(f'\t\t\t\t{ids["iphone_fw"]} /* Frameworks */,')
    w(f'\t\t\t\t{ids["iphone_resources_phase"]} /* Resources */,')
    w('\t\t\t);')
    w('\t\t\tbuildRules = (')
    w('\t\t\t);')
    w('\t\t\tdependencies = (')
    w('\t\t\t);')
    w('\t\t\tname = QiHuangPulse;')
    w('\t\t\tproductName = QiHuangPulse;')
    w(f'\t\t\tproductReference = {ids["iphone_product"]} /* QiHuangPulse.app */;')
    w('\t\t\tproductType = "com.apple.product-type.application";')
    w('\t\t};')
    
    # Watch target
    w(f'\t\t{ids["watch_target"]} /* QiHuangWatch */ = {{')
    w('\t\t\tisa = PBXNativeTarget;')
    w(f'\t\t\tbuildConfigurationList = {ids["watch_build_config_list"]};')
    w(f'\t\t\tbuildPhases = (')
    w(f'\t\t\t\t{ids["watch_sources_phase"]} /* Sources */,')
    w(f'\t\t\t\t{ids["watch_fw"]} /* Frameworks */,')
    w(f'\t\t\t\t{ids["watch_resources_phase"]} /* Resources */,')
    w('\t\t\t);')
    w('\t\t\tbuildRules = (')
    w('\t\t\t);')
    w('\t\t\tdependencies = (')
    w(f'\t\t\t\t{ids["target_dep"]} /* PBXTargetDependency */,')
    w('\t\t\t);')
    w('\t\t\tname = QiHuangWatch;')
    w('\t\t\tproductName = QiHuangWatch;')
    w(f'\t\t\tproductReference = {ids["watch_product"]} /* QiHuangWatch.app */;')
    w('\t\t\tproductType = "com.apple.product-type.application";')
    w('\t\t};')
    
    w('/* End PBXNativeTarget section */')
    w('')
    
    # ─── PBXProject ───
    w('/* Begin PBXProject section */')
    w(f'\t\t{gen_id("project")} /* Project object */ = {{')
    w('\t\t\tisa = PBXProject;')
    w(f'\t\t\tbuildConfigurationList = {ids["project_config_list"]};')
    w('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    w('\t\t\tdevelopmentRegion = zh_CN;')
    w('\t\t\thasScannedForEncodings = 0;')
    w('\t\t\tknownRegions = (')
    w('\t\t\t\tzh_CN,')
    w('\t\t\t\tBase,')
    w('\t\t\t);')
    w(f'\t\t\tmainGroup = {ids["root_group"]};')
    w(f'\t\t\tproductRefGroup = {ids["products_group"]} /* Products */;')
    w('\t\t\tprojectDirPath = "";')
    w('\t\t\tprojectRoot = "";')
    w('\t\t\ttargets = (')
    w(f'\t\t\t\t{ids["iphone_target"]} /* QiHuangPulse */,')
    w(f'\t\t\t\t{ids["watch_target"]} /* QiHuangWatch */,')
    w('\t\t\t);')
    w('\t\t};')
    w('/* End PBXProject section */')
    w('')
    
    # ─── PBXSourcesBuildPhase ───
    w('/* Begin PBXSourcesBuildPhase section */')
    
    # iPhone sources
    w(f'\t\t{ids["iphone_sources_phase"]} /* Sources */ = {{')
    w('\t\t\tisa = PBXSourcesBuildPhase;')
    w('\t\t\tbuildActionMask = 2147483647;')
    w('\t\t\tfiles = (')
    for f in iphone_files:
        w(f'\t\t\t\t{ids["iphone"][f]["build_file"]} /* {os.path.basename(f)} */,')
    for f in shared_models + shared_services + shared_viewmodels + shared_config:
        w(f'\t\t\t\t{ids["shared"][f]["build_file"]} /* {os.path.basename(f)} */,')
    w('\t\t\t);')
    w('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    w('\t\t};')
    
    # Watch sources
    w(f'\t\t{ids["watch_sources_phase"]} /* Sources */ = {{')
    w('\t\t\tisa = PBXSourcesBuildPhase;')
    w('\t\t\tbuildActionMask = 2147483647;')
    w('\t\t\tfiles = (')
    for f in watch_app + watch_views:
        key = "watch_views" if f in ids["watch_views"] else "watch_app"
        w(f'\t\t\t\t{ids[key][f]["build_file"]} /* {os.path.basename(f)} */,')
    for f in shared_models + shared_services + shared_viewmodels + shared_config:
        w(f'\t\t\t\t{ids["shared"][f]["build_file"]} /* {os.path.basename(f)} */,')
    w('\t\t\t);')
    w('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    w('\t\t};')
    
    w('/* End PBXSourcesBuildPhase section */')
    w('')
    
    # ─── PBXResourcesBuildPhase ───
    w('/* Begin PBXResourcesBuildPhase section */')
    w(f'\t\t{ids["iphone_resources_phase"]} /* Resources */ = {{')
    w('\t\t\tisa = PBXResourcesBuildPhase;')
    w('\t\t\tbuildActionMask = 2147483647;')
    w('\t\t\tfiles = (')
    w('\t\t\t);')
    w('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    w('\t\t};')
    w(f'\t\t{ids["watch_resources_phase"]} /* Resources */ = {{')
    w('\t\t\tisa = PBXResourcesBuildPhase;')
    w('\t\t\tbuildActionMask = 2147483647;')
    w('\t\t\tfiles = (')
    w('\t\t\t);')
    w('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    w('\t\t};')
    w('/* End PBXResourcesBuildPhase section */')
    w('')
    
    # ─── XCBuildConfiguration ───
    w('/* Begin XCBuildConfiguration section */')
    
    def write_config(cid, name, settings, is_debug=True):
        w(f'\t\t{cid} /* {name} */ = {{')
        w('\t\t\tisa = XCBuildConfiguration;')
        w('\t\t\tbuildSettings = {')
        for k, v in sorted(settings.items()):
            w(f'\t\t\t\t{k} = {v};')
        w('\t\t\t};')
        w(f'\t\t\tname = {name};')
        w('\t\t};')
    
    common_ios = {
        'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
        'CODE_SIGN_STYLE': 'Automatic',
        'CURRENT_PROJECT_VERSION': '1',
        'DEVELOPMENT_ASSET_PATHS': '""',
        'ENABLE_PREVIEWS': 'YES',
        'GENERATE_INFOPLIST_FILE': 'YES',
        'INFOPLIST_KEY_CFBundleDisplayName': '"岐黄脉镜"',
        'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES',
        'INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents': 'YES',
        'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
        'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad': '"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"',
        'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone': '"UIInterfaceOrientationPortrait"',
        'MARKETING_VERSION': '1.0.0',
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.qihuang.pulse.iphone',
        'SDKROOT': 'iphoneos',
        'SWIFT_EMIT_LOC_STRINGS': 'YES',
        'SWIFT_VERSION': '5.0',
        'TARGETED_DEVICE_FAMILY': '"1,2"',
    }
    
    common_watch = {
        'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
        'ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME': 'WidgetBackground',
        'CODE_SIGN_STYLE': 'Automatic',
        'CURRENT_PROJECT_VERSION': '1',
        'DEVELOPMENT_ASSET_PATHS': '""',
        'ENABLE_PREVIEWS': 'YES',
        'GENERATE_INFOPLIST_FILE': 'YES',
        'INFOPLIST_KEY_CFBundleDisplayName': '"岐黄脉镜"',
        'INFOPLIST_KEY WKApplication': 'YES',
        'INFOPLIST_KEY_WKCompanionAppBundleIdentifier': 'com.qihuang.pulse.iphone',
        'INFOPLIST_KEY_WKSupportedInterfaceOrientations': '"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown"',
        'MARKETING_VERSION': '1.0.0',
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.qihuang.pulse.watchkitapp',
        'SDKROOT': 'watchos',
        'SWIFT_EMIT_LOC_STRINGS': 'YES',
        'SWIFT_VERSION': '5.0',
        'WATCHOS_DEPLOYMENT_TARGET': '10.0',
    }
    
    # iPhone Debug
    ios_debug = {**common_ios, 'DEBUG_INFORMATION_FORMAT': 'dwarf', 'ENABLE_TESTABILITY': 'YES', 'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'MTL_ENABLE_DEBUG_INFO': 'YES', 'ONLY_ACTIVE_ARCH': 'YES', 'SDKROOT': 'iphoneos', 'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG'}
    write_config(ids['iphone_debug'], 'Debug', ios_debug)
    ios_release = {**common_ios, 'DEBUG_INFORMATION_FORMAT': '"dwarf-with-dsym"', 'ENABLE_NS_ASSERTIONS': 'NO', 'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SDKROOT': 'iphoneos', 'SWIFT_COMPILATION_MODE': 'wholemodule', 'VALIDATE_PRODUCT': 'YES'}
    write_config(ids['iphone_release'], 'Release', ios_release)
    
    # Watch Debug
    watch_debug = {**common_watch, 'DEBUG_INFORMATION_FORMAT': 'dwarf', 'ENABLE_TESTABILITY': 'YES', 'MTL_ENABLE_DEBUG_INFO': 'YES', 'ONLY_ACTIVE_ARCH': 'YES', 'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG'}
    write_config(ids['watch_debug'], 'Debug', watch_debug)
    watch_release = {**common_watch, 'DEBUG_INFORMATION_FORMAT': '"dwarf-with-dsym"', 'ENABLE_NS_ASSERTIONS': 'NO', 'SWIFT_COMPILATION_MODE': 'wholemodule', 'VALIDATE_PRODUCT': 'YES'}
    write_config(ids['watch_release'], 'Release', watch_release)
    
    # Project configs
    proj_debug = {'ALWAYS_SEARCH_USER_PATHS': 'NO', 'CLANG_ANALYZER_NONNULL': 'YES', 'CLANG_CXX_LANGUAGE_STANDARD': '"gnu++20"', 'CLANG_ENABLE_MODULES': 'YES', 'CLANG_ENABLE_OBJC_ARC': 'YES', 'COPY_PHASE_STRIP': 'NO', 'DEBUG_INFORMATION_FORMAT': 'dwarf', 'ENABLE_STRICT_OBJC_MSGSEND': 'YES', 'ENABLE_TESTABILITY': 'YES', 'GCC_DYNAMIC_NO_PIC': 'NO', 'GCC_OPTIMIZATION_LEVEL': '0', 'GCC_PREPROCESSOR_DEFINITIONS': '"DEBUG=1 $(inherited)"', 'MTL_ENABLE_DEBUG_INFO': 'YES', 'ONLY_ACTIVE_ARCH': 'YES', 'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG'}
    write_config(ids['project_debug'], 'Debug', proj_debug)
    proj_release = {'ALWAYS_SEARCH_USER_PATHS': 'NO', 'CLANG_ANALYZER_NONNULL': 'YES', 'CLANG_CXX_LANGUAGE_STANDARD': '"gnu++20"', 'CLANG_ENABLE_MODULES': 'YES', 'CLANG_ENABLE_OBJC_ARC': 'YES', 'COPY_PHASE_STRIP': 'NO', 'DEBUG_INFORMATION_FORMAT': '"dwarf-with-dsym"', 'ENABLE_NS_ASSERTIONS': 'NO', 'ENABLE_STRICT_OBJC_MSGSEND': 'YES', 'MTL_ENABLE_DEBUG_INFO': 'NO', 'SWIFT_COMPILATION_MODE': 'wholemodule', 'VALIDATE_PRODUCT': 'YES'}
    write_config(ids['project_release'], 'Release', proj_release)
    
    w('/* End XCBuildConfiguration section */')
    w('')
    
    # ─── PBXTargetDependency ───
    w('/* Begin PBXTargetDependency section */')
    w(f'\t\t{ids["target_dep"]} /* PBXTargetDependency */ = {{')
    w('\t\t\tisa = PBXTargetDependency;')
    w(f'\t\t\ttarget = {ids["iphone_target"]} /* QiHuangPulse */;')
    w(f'\t\t\ttargetProxy = {ids["container_proxy"]} /* PBXContainerItemProxy */;')
    w('\t\t};')
    w('/* End PBXTargetDependency section */')
    w('')
    
    # ─── PBXContainerItemProxy ───
    w('/* Begin PBXContainerItemProxy section */')
    w(f'\t\t{ids["container_proxy"]} /* PBXContainerItemProxy */ = {{')
    w('\t\t\tisa = PBXContainerItemProxy;')
    w('\t\t\tcontainerPortal = <PBXProject>;')
    w('\t\t\tproxyType = 1;')
    w(f'\t\t\tremoteGlobalIDString = {ids["iphone_target"]};')
    w('\t\t\tremoteInfo = QiHuangPulse;')
    w('\t\t};')
    w('/* End PBXContainerItemProxy section */')
    w('')
    
    # ─── XCConfigurationList ───
    w('/* Begin XCConfigurationList section */')
    w(f'\t\t{ids["iphone_build_config_list"]} /* Build configuration list for PBXNativeTarget "QiHuangPulse" */ = {{')
    w('\t\t\tisa = XCConfigurationList;')
    w('\t\t\tbuildConfigurations = (')
    w(f'\t\t\t\t{ids["iphone_debug"]} /* Debug */,')
    w(f'\t\t\t\t{ids["iphone_release"]} /* Release */,')
    w('\t\t\t);')
    w('\t\t\tdefaultConfigurationIsVisible = 0;')
    w('\t\t\tdefaultConfigurationName = Release;')
    w('\t\t};')
    w(f'\t\t{ids["watch_build_config_list"]} /* Build configuration list for PBXNativeTarget "QiHuangWatch" */ = {{')
    w('\t\t\tisa = XCConfigurationList;')
    w('\t\t\tbuildConfigurations = (')
    w(f'\t\t\t\t{ids["watch_debug"]} /* Debug */,')
    w(f'\t\t\t\t{ids["watch_release"]} /* Release */,')
    w('\t\t\t);')
    w('\t\t\tdefaultConfigurationIsVisible = 0;')
    w('\t\t\tdefaultConfigurationName = Release;')
    w('\t\t};')
    w(f'\t\t{ids["project_config_list"]} /* Build configuration list for PBXProject "QiHuangPulse" */ = {{')
    w('\t\t\tisa = XCConfigurationList;')
    w('\t\t\tbuildConfigurations = (')
    w(f'\t\t\t\t{ids["project_debug"]} /* Debug */,')
    w(f'\t\t\t\t{ids["project_release"]} /* Release */,')
    w('\t\t\t);')
    w('\t\t\tdefaultConfigurationIsVisible = 0;')
    w('\t\t\tdefaultConfigurationName = Release;')
    w('\t\t};')
    w('/* End XCConfigurationList section */')
    w('')
    
    w('\t};')
    w(f'\trootObject = {gen_id("project")} /* Project object */;')
    w('}')
    
    return '\n'.join(lines)

# ═══════════════════════════════════════════
# Main
# ═══════════════════════════════════════════

if __name__ == '__main__':
    # Create .xcodeproj structure
    proj_dir = 'QiHuangPulse.xcodeproj'
    os.makedirs(proj_dir, exist_ok=True)
    
    # Write project.pbxproj
    pbxproj = generate_pbxproj()
    with open(os.path.join(proj_dir, 'project.pbxproj'), 'w') as f:
        f.write(pbxproj)
    
    # Write xcschemes
    schemes_dir = os.path.join(proj_dir, 'xcshareddata', 'xcschemes')
    os.makedirs(schemes_dir, exist_ok=True)
    
    print(f'✅ Generated {proj_dir}/project.pbxproj')
    print(f'   Size: {len(pbxproj)} bytes')
    print(f'   Lines: {pbxproj.count(chr(10))}')
