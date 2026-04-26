// 文件路径: entry/src/main/ets/pages/StatisticsPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { PieChart } from '../components/PieChart';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { CategoryColors } from '../model/BillModel';

interface CategorySummaryItem {
  category: string;
  amount: number;
}
@Entry
@Component
struct StatisticsPage {
  @State viewModel: BillViewModel = new BillViewModel();
  @State selectedTab: number = 0; // 0: 饼图, 1: 列表

  async aboutToAppear(): Promise<void> {
    await this.viewModel.loadBills();
  }

  build() {
    Column() {
      // 月份选择器
      Row() {
        Text(this.viewModel.currentMonth)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Center)

      // 切换视图
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
        // 饼图视图
        PieChart({ data: this.viewModel.getCategorySummary() })
          .width('100%')
          .height(300)
      } else {
        // 分类详情列表
        List() {
          ForEach(this.viewModel.getCategorySummary(), (item: CategorySummaryItem) => {
            ListItem() {
              Row() {
                Circle({ width: 12, height: 12 })
                  .fill(CategoryColors[item.category] || '#CCCCCC')

                Text(item.category)
                  .fontSize(16)
                  .margin({ left: 8 })
                  .layoutWeight(1)

                Text(`¥${CurrencyUtil.fenToYuan(item.amount)}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)

                Text(`${((item.amount / this.viewModel.monthlyTotal) * 100).toFixed(1)}%`)
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ left: 8 })
              }
              .width('90%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ left: '5%', right: '5%', top: 4, bottom: 4 })
            }
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}