import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { Hypium } from '@ohos/hypium';
import { Driver } from '@ohos.UiTest';
import testsuite from '../test/List.test';

let domain: number = 0x0000;
let tag: string = 'testTag';

export default class OpenHarmonyTestRunner implements TestRunner {

  onPrepare() {
    hilog.info(domain, tag, 'OpenHarmonyTestRunner onPrepare');

    // 先创建 UiTest 驱动，它绑定当前设备屏幕
    globalThis.driver = Driver.create();
  }

  async onRun() {
    hilog.info(domain, tag, 'OpenHarmonyTestRunner onRun start');

    let abilityDelegatorArguments = abilityDelegatorRegistry.getArguments();
    let abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    let moduleName = abilityDelegatorArguments.parameters['-m'];
    let context = abilityDelegator.getAppContext().getApplicationContext().createModuleContext(moduleName);
    let mResourceManager = context.resourceManager;

    // Mock 初始化
    await checkMock(abilityDelegator, mResourceManager);

    // 启动被测应用，必须在 Driver.create() 之后
    await abilityDelegator.startAbility({
      bundleName: 'com.example.count1',
      abilityName: 'EntryAbility'
    });

    // 等待应用完全渲染
    await (globalThis.driver as Driver).delayMs(4000);

    hilog.info(domain, tag, 'App launched with UiTest driver, running tests');

    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);

    hilog.info(domain, tag, 'OpenHarmonyTestRunner onRun end');
  }
}

async function checkMock(abilityDelegator: abilityDelegatorRegistry.AbilityDelegator, resourceManager: resourceManager.ResourceManager) {
  let rawFile: Uint8Array;
  try {
    rawFile = resourceManager.getRawFileContentSync('mock/mock-config.json');
    hilog.info(domain, tag, 'MockList file exists');
    let mockStr: string = util.TextDecoder.create("utf-8", { ignoreBOM: true }).decodeWithStream(rawFile);
    let mockMap: Record<string, string> = getMockList(mockStr);
    try {
      abilityDelegator.setMockList(mockMap);
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      hilog.error(domain, tag, `setMockList failed, code: ${code}, msg: ${message}`);
    }
  } catch (error) {
    let code = (error as BusinessError).code;
    let message = (error as BusinessError).message;
    hilog.error(domain, tag, `getRawFileContent failed, code: ${code}, msg: ${message}`);
  }
}

function getMockList(jsonStr: string) {
  let jsonObj: Record<string, Object> = JSON.parse(jsonStr);
  let map: Map<string, object> = new Map<string, object>(Object.entries(jsonObj));
  let mockList: Record<string, string> = {};
  map.forEach((value: object, key: string) => {
    let realValue: string = value['source'].toString();
    mockList[key] = realValue;
  });
  return mockList;
}
