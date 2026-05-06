// 文件路径: entry/src/main/ets/pages/Index.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { CategoryType } from '../model/BillModel';
import { BillModel } from '../model/BillModel';
import { DatabaseHelper } from '../database/DatabaseHelper';
import router from '@ohos.router';

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
  @State refreshFlag: number = 0;

  private categoryOptions: SelectOption[] = this.createCategoryOptions();
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();
    this.categoryOptions = this.createCategoryOptions();
    await this.refreshData();
  }

  onPageShow(): void {
    // 从添加账单、预算、统计等页面返回首页时，重新加载当前月份数据
    this.refreshData();
  }

  async refreshData(): Promise<void> {
    try {
      await this.viewModel.loadBills(this.searchKeyword, this.filterCategory);
      await this.viewModel.loadBudget();

      // 用于强制触发部分 UI 重新计算
      this.refreshFlag++;
    } catch (error) {
      console.error('Error refreshing data:', error);
    }
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
      this.buildHeader();
      this.buildMonthSelector();
      this.buildBudgetCard();
      this.buildSearchBar();
      this.buildActionButtons();

      if (this.viewModel.bills.length === 0) {
        Column() {
          Text('当前月份暂无账单')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 40 })

          Text('可以切换月份查看其他账单')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F5F5F5')
      } else {
        List() {
          ForEach(this.viewModel.bills, (bill: BillModel) => {
            ListItem() {
              this.buildBillItem(bill)
            }
            .swipeAction({
              end: this.buildSwipeActions(bill)
            })
          }, (bill: BillModel) => {
            return bill.id.toString();
          })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildHeader() {
    Row() {
      Text('智慧记账')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank()

      Button() {
        Text('📊')
          .fontSize(20)
      }
      .width(40)
      .height(40)
      .backgroundColor('#F0F0F0')
      .borderRadius(20)
      .margin({ right: 8 })
      .onClick(async () => {
        await router.pushUrl({
          url: 'pages/StatisticsPage',
          params: {
            month: this.viewModel.currentMonth
          }
        });
      })

      Button() {
        Text('💰')
          .fontSize(20)
      }
      .width(40)
      .height(40)
      .backgroundColor('#F0F0F0')
      .borderRadius(20)
      .margin({ right: 8 })
      .onClick(async () => {
        await router.pushUrl({
          url: 'pages/BudgetPage',
          params: {
            month: this.viewModel.currentMonth
          }
        });
      })

      Button() {
        Text('✨')
          .fontSize(20)
      }
      .width(40)
      .height(40)
      .backgroundColor('#F0F0F0')
      .borderRadius(20)
      .onClick(async () => {
        await router.pushUrl({
          url: 'pages/SpendingInsightPage',
          params: {
            month: this.viewModel.currentMonth
          }
        });
      })
    }
    .width('90%')
    .padding({
      top: 16,
      bottom: 8
    })
  }

  @Builder
  buildMonthSelector() {
    Row() {
      Button('上月')
        .fontSize(13)
        .height(36)
        .backgroundColor('#F5F5F5')
        .fontColor('#333333')
        .borderRadius(18)
        .onClick(async () => {
          await this.viewModel.goPreviousMonth(this.searchKeyword, this.filterCategory);
          this.refreshFlag++;
        })

      Blank()

      Text(this.viewModel.currentMonth)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank()

      Button('下月')
        .fontSize(13)
        .height(36)
        .backgroundColor('#F5F5F5')
        .fontColor('#333333')
        .borderRadius(18)
        .onClick(async () => {
          await this.viewModel.goNextMonth(this.searchKeyword, this.filterCategory);
          this.refreshFlag++;
        })

      Button('本月')
        .fontSize(13)
        .height(36)
        .backgroundColor('#4CAF50')
        .fontColor('#FFFFFF')
        .borderRadius(18)
        .margin({ left: 8 })
        .onClick(async () => {
          await this.viewModel.goCurrentMonth(this.searchKeyword, this.filterCategory);
          this.refreshFlag++;
        })
    }
    .width('90%')
    .height(44)
    .margin({
      top: 4,
      bottom: 8
    })
  }

  @Builder
  buildBudgetCard() {
    Column() {
      Row() {
        Text(`${this.viewModel.currentMonth} 剩余`)
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
        .style({
          strokeWidth: 8,
          strokeRadius: 4
        })
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
    .shadow({
      radius: 8,
      color: '#10000000',
      offsetX: 0,
      offsetY: 2
    })
    .margin({
      top: 8,
      bottom: 12
    })
  }

  @Builder
  buildSearchBar() {
    Row() {
      TextInput({
        placeholder: '搜索备注关键字',
        text: this.searchKeyword
      })
        .layoutWeight(1)
        .height(36)
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .padding({
          left: 12,
          right: 12
        })
        .onChange((value: string) => {
          this.searchKeyword = value;
        })
        .onSubmit(async () => {
          await this.refreshData();
        })

      Select(this.categoryOptions)
        .selected(this.getSelectedIndex())
        .value(this.filterCategory || '全部类型')
        .font({
          size: 14
        })
        .selectedOptionBgColor('#E3F2FD')
        .optionBgColor('#FFFFFF')
        .width(100)
        .height(36)
        .margin({ left: 8 })
        .onSelect(async (index: number, value?: string) => {
          if (index === 0) {
            this.filterCategory = '';
          } else {
            this.filterCategory = value || '';
          }

          await this.refreshData();
        })
    }
    .width('90%')
    .margin({ bottom: 8 })
  }

  @Builder
  buildActionButtons() {
    Row() {
      Button() {
        Row() {
          Text('+')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 4 })

          Text('记一笔')
            .fontSize(16)
        }
      }
      .width('45%')
      .height(48)
      .backgroundColor('#4CAF50')
      .borderRadius(24)
      .onClick(async () => {
        await router.pushUrl({
          url: 'pages/AddBillPage'
        });
      })

      Blank()

      Button() {
        Row() {
          Text('📈')
            .fontSize(16)
            .margin({ right: 4 })

          Text('消费统计')
            .fontSize(16)
        }
      }
      .width('45%')
      .height(48)
      .backgroundColor('#2196F3')
      .borderRadius(24)
      .onClick(async () => {
        await router.pushUrl({
          url: 'pages/StatisticsPage',
          params: {
            month: this.viewModel.currentMonth
          }
        });
      })
    }
    .width('90%')
    .margin({
      top: 4,
      bottom: 8
    })
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
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
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
    .margin({
      left: '5%',
      right: '5%',
      top: 6,
      bottom: 6
    })
    .onClick(async () => {
      await router.pushUrl({
        url: 'pages/AddBillPage',
        params: {
          billId: String(bill.id),
          amount: CurrencyUtil.fenToYuan(bill.amount),
          category: bill.category,
          date: bill.date,
          remark: bill.remark || ''
        }
      });
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
      await this.refreshData();
    })
  }
}