// 文件路径: entry/src/main/ets/pages/StatisticsPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { PieChart } from '../components/PieChart';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { CategoryColors } from '../model/BillModel';
import { DatabaseHelper } from '../database/DatabaseHelper';
import router from '@ohos.router';
import { window } from '@kit.ArkUI';

interface CategorySummaryItem {
  category: string;
  amount: number;
}

@Entry
@Component
struct StatisticsPage {
  @State viewModel: BillViewModel = new BillViewModel();
  @State selectedTab: number = 0;
  @State selectedMonth: string = '';
  @State refreshFlag: number = 0;
  @State isTablet: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = 'sm';

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  private formatMonth(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
  }

  private parseMonth(month: string): Date {
    const parts = month.split('-');

    if (parts.length !== 2) {
      return new Date();
    }

    const year = Number(parts[0]);
    const monthIndex = Number(parts[1]) - 1;

    if (isNaN(year) || isNaN(monthIndex)) {
      return new Date();
    }

    return new Date(year, monthIndex, 1);

  }

  private async detectTabletMode(): Promise<void> {
    if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
      this.isTablet = true;
      return;
    }
    try {
      const win = await window.getLastWindow(getContext(this));
      const props = win.getWindowProperties();
      const rect = props.windowRect;
      const widthVp: number = px2vp(rect.width) as number;
      if (widthVp >= 600) {
        this.isTablet = true;
      }
    } catch (e) {
      // 不可用时保持默认值 false
    }
  }

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();
    await this.detectTabletMode();

    const params = router.getParams() as Record<string, Object>;

    if (params && params['month']) {
      const monthParam = String(params['month']);

      if (monthParam.length === 7) {
        this.selectedMonth = monthParam;
      } else {
        this.selectedMonth = this.formatMonth(new Date());
      }
    } else {
      this.selectedMonth = this.formatMonth(new Date());
    }

    await this.loadStatisticsByMonth();

  }

  async loadStatisticsByMonth(): Promise<void> {
    await this.viewModel.changeMonth(this.selectedMonth);
    this.refreshFlag++;
  }

  async goPreviousMonth(): Promise<void> {
    const date = this.parseMonth(this.selectedMonth);
    date.setMonth(date.getMonth() - 1);
    this.selectedMonth = this.formatMonth(date);

    await this.loadStatisticsByMonth();

  }

  async goNextMonth(): Promise<void> {
    const date = this.parseMonth(this.selectedMonth);
    date.setMonth(date.getMonth() + 1);
    this.selectedMonth = this.formatMonth(date);

    await this.loadStatisticsByMonth();

  }

  async goCurrentMonth(): Promise<void> {
    this.selectedMonth = this.formatMonth(new Date());

    await this.loadStatisticsByMonth();

  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('返回').backgroundColor('#00000000').fontColor('#4CAF50')
          .onClick(() => { router.back(); })
        Text('消费统计').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(56)
      }
      .width(this.isTablet ? '95%' : '90%').height(48).margin({ top: 8 })

      this.buildMonthSelector()

      // 当月总消费
      Column() {
        Text(`${this.selectedMonth} 总消费`).fontSize(14).fontColor('#666666')
        Text(`¥${CurrencyUtil.fenToYuan(this.viewModel.monthlyTotal)}`)
          .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#D32F2F').margin({ top: 4 })
      }
      .width(this.isTablet ? '95%' : '90%').padding(16)
      .backgroundColor('#FFFFFF').borderRadius(12)
      .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
      .margin({ bottom: 12 })

      if (this.viewModel.getCategorySummary().length === 0) {
        Column() {
          Text('当前月份暂无消费数据').fontSize(16).fontColor('#999999').margin({ top: 40 })
          Text('可以切换月份查看其他统计').fontSize(12).fontColor('#BBBBBB').margin({ top: 8 })
        }
        .layoutWeight(1).width('100%')
      } else if (this.isTablet) {
        // ===== 平板模式：饼图 + 详情并排 =====
        Row() {
          Scroll() {
            Column() {
              PieChart({ data: this.viewModel.getCategorySummary() })
                .key(`pie-tablet-${this.refreshFlag}`)
            }.width('100%')
          }
          .layoutWeight(1).height('100%').scrollBar(BarState.Auto).padding({ left: 8, right: 8 })

          List() {
            ForEach(this.viewModel.getCategorySummary(), (item: CategorySummaryItem) => {
              ListItem() {
                Row() {
                  Circle({ width: 12, height: 12 }).fill(CategoryColors[item.category] || '#CCCCCC')
                  Text(item.category).fontSize(16).margin({ left: 8 }).layoutWeight(1)
                  Text(`¥${CurrencyUtil.fenToYuan(item.amount)}`).fontSize(16).fontWeight(FontWeight.Bold)
                  Text(this.viewModel.monthlyTotal > 0
                    ? `${((item.amount / this.viewModel.monthlyTotal) * 100).toFixed(1)}%`
                    : '0.0%')
                    .fontSize(14).fontColor('#999999').margin({ left: 8 })
                }
                .width('95%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
                .margin({ left: '2.5%', right: '2.5%', top: 4, bottom: 4 })
              }
            })
          }
          .layoutWeight(1).height('100%')
        }
        .layoutWeight(1).width('100%').padding({ left: 8, right: 8 })
      } else {
        // ===== 手机模式：Tab 切换 =====
        Row() {
          Button('饼图')
            .type(this.selectedTab === 0 ? ButtonType.Capsule : ButtonType.Normal)
            .backgroundColor(this.selectedTab === 0 ? '#4CAF50' : '#F5F5F5')
            .fontColor(this.selectedTab === 0 ? '#FFFFFF' : '#333333')
            .onClick(() => { this.selectedTab = 0; })
          Button('详情')
            .type(this.selectedTab === 1 ? ButtonType.Capsule : ButtonType.Normal)
            .backgroundColor(this.selectedTab === 1 ? '#4CAF50' : '#F5F5F5')
            .fontColor(this.selectedTab === 1 ? '#FFFFFF' : '#333333')
            .margin({ left: 12 })
            .onClick(() => { this.selectedTab = 1; })
        }
        .margin({ bottom: 16 })

        if (this.selectedTab === 0) {
          Scroll() {
            Column() {
              PieChart({ data: this.viewModel.getCategorySummary() })
                .key(`pie-${this.refreshFlag}`)
            }.width('100%').padding({ bottom: 32 })
          }
          .layoutWeight(1).width('100%').scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
        } else {
          List() {
            ForEach(this.viewModel.getCategorySummary(), (item: CategorySummaryItem) => {
              ListItem() {
                Row() {
                  Circle({ width: 12, height: 12 }).fill(CategoryColors[item.category] || '#CCCCCC')
                  Text(item.category).fontSize(16).margin({ left: 8 }).layoutWeight(1)
                  Text(`¥${CurrencyUtil.fenToYuan(item.amount)}`).fontSize(16).fontWeight(FontWeight.Bold)
                  Text(this.viewModel.monthlyTotal > 0
                    ? `${((item.amount / this.viewModel.monthlyTotal) * 100).toFixed(1)}%`
                    : '0.0%')
                    .fontSize(14).fontColor('#999999').margin({ left: 8 })
                }
                .width('90%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
                .margin({ left: '5%', right: '5%', top: 4, bottom: 4 })
              }
            })
          }
          .layoutWeight(1).width('100%')
        }
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  buildMonthSelector() {
    Row() {
      Button('上月').fontSize(13).height(36).backgroundColor('#F5F5F5').fontColor('#333333').borderRadius(18)
        .onClick(async () => { await this.goPreviousMonth(); })
      Blank()
      Text(this.selectedMonth).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333333')
      Blank()
      Button('下月').fontSize(13).height(36).backgroundColor('#F5F5F5').fontColor('#333333').borderRadius(18)
        .onClick(async () => { await this.goNextMonth(); })
      Button('本月').fontSize(13).height(36).backgroundColor('#4CAF50').fontColor('#FFFFFF').borderRadius(18)
        .margin({ left: 8 })
        .onClick(async () => { await this.goCurrentMonth(); })
    }
    .width(this.isTablet ? '95%' : '90%').height(44).margin({ top: 8, bottom: 12 })
  }
}