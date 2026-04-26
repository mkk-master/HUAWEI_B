// 文件路径: entry/src/main/ets/pages/Index.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { CategoryType } from '../model/BillModel';
import { BillModel } from '../model/BillModel';
interface SelectOption {
  value: ResourceStr;
  icon?: ResourceStr;
}
@Entry
@Component
struct Index {
  @State viewModel: BillViewModel = new BillViewModel();
  @State searchKeyword: string = '';
  @State filterCategory: string = '';
  private categoryOptions: SelectOption[] = this.createCategoryOptions();

  async aboutToAppear(): Promise<void> {
    await this.viewModel.init();
  }
  private createCategoryOptions(): SelectOption[] {
    const options: SelectOption[] = [
      { value: '全部类型' as ResourceStr }
    ];

    const categories = Object.values(CategoryType);
    categories.forEach((category: string) => {
      options.push({ value: category as ResourceStr });
    });

    return options;
  }
  build() {
    Column() {
      // 顶部预算卡片
      this.buildBudgetCard();

      // 搜索筛选栏
      this.buildSearchBar();

      // 账单列表
      List() {
        ForEach(this.viewModel.bills, (bill: BillModel) => {
          ListItem() {
            this.buildBillItem(bill)
          }
          .swipeAction({ end: this.buildSwipeActions(bill) })
        }, (bill: BillModel) => bill.id.toString())
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildBudgetCard() {
    Column() {
      Row() {
        Text('本月剩余')
          .fontSize(14)
          .fontColor('#666666')
        Text(`${CurrencyUtil.fenToYuan(this.viewModel.getRemainingBudget())} 元`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.viewModel.getRemainingBudget() >= 0 ? '#2E7D32' : '#D32F2F')
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Progress({
        value: this.viewModel.getBudgetProgress() * 100,
        total: 100,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(8)
        .style({ strokeWidth: 8, strokeRadius: 4 })
        .color(this.viewModel.getRemainingBudget() >= 0 ? '#4CAF50' : '#F44336')
        .margin({ top: 8 })

      Row() {
        Text(`预算 ${CurrencyUtil.fenToYuan(this.viewModel.monthlyBudget)}`)
          .fontSize(12)
          .fontColor('#999999')
        Text(`已花 ${CurrencyUtil.fenToYuan(this.viewModel.monthlyTotal)}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 4 })
    }
    .width('90%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
    .margin({ top: 16, bottom: 12 })
  }

  @Builder
  buildSearchBar() {
    Row() {
      // 搜索框
      TextInput({ placeholder: '搜索备注关键字', text: this.searchKeyword })
        .layoutWeight(1)
        .height(36)
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.searchKeyword = value;
        })
        .onSubmit(() => {
          this.viewModel.loadBills(this.searchKeyword, this.filterCategory);
        })

      // 分类筛选
      Select(this.categoryOptions)
        .selected(this.getSelectedIndex())
        .value(this.filterCategory || '全部类型')
        .font({ size: 14 })
        .selectedOptionBgColor('#E3F2FD')
        .optionBgColor('#FFFFFF')
        .width(100)
        .height(36)
        .margin({ left: 8 })
        .onSelect((index: number, value?: string) => {
          if (index === 0) {
            this.filterCategory = ''; // 选择"全部类型"
          } else {
            this.filterCategory = value || '';
          }
          this.viewModel.loadBills(this.searchKeyword, this.filterCategory);
        })
    }
    .width('90%')
    .margin({ bottom: 8 })
  }
  private getSelectedIndex(): number {
    if (!this.filterCategory) {
      return 0;
    }

    for (let i = 0; i < this.categoryOptions.length; i++) {
      if (this.categoryOptions[i].value === this.filterCategory) {
        return i;
      }
    }

    return 0;
  }
  @Builder
  buildBillItem(bill: BillModel) {
    Row() {
      Column() {
        Text(bill.category)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text(bill.remark || '无备注')
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(`-${CurrencyUtil.fenToYuan(bill.amount)}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D32F2F')
        Text(bill.date)
          .fontSize(11)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('90%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: '5%', right: '5%', top: 6, bottom: 6 })
    .onClick(() => {
      // 可添加编辑功能
    })
  }

  @Builder
  buildSwipeActions(bill: BillModel) {
    Button() {
      Text('删除')
        .fontSize(14)
        .fontColor('#FFFFFF')
    }
    .width(80)
    .height('100%')
    .backgroundColor('#F44336')
    .onClick(async () => {
      await this.viewModel.deleteBill(bill.id);
    })
  }
}