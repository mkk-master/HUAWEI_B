// 文件路径: entry/src/main/ets/pages/AddBillPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CategoryType } from '../model/BillModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { DatabaseHelper } from '../database/DatabaseHelper';
import router from '@ohos.router';

interface DatePickerResult {
  year: number;
  month: number;
  day: number;
}

@Entry
@Component
struct AddBillPage {
  @State amountInput: string = '';
  @State selectedCategory: CategoryType = CategoryType.FOOD;
  @State date: string = this.formatDate(new Date());
  @State remark: string = '';
  @State amountError: string = '';
  @State isEdit: boolean = false;
  @State editBillId: number = -1;
  @State pageTitle: string = '记一笔';

  private viewModel: BillViewModel = new BillViewModel();
  private categoryArray: CategoryType[] = Object.values(CategoryType);
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private parseDate(dateStr: string): Date {
    if (!dateStr || dateStr.trim().length === 0) {
      return new Date();
    }

    const parts = dateStr.split('-');
    if (parts.length !== 3) {
      return new Date();
    }

    const year = Number(parts[0]);
    const month = Number(parts[1]);
    const day = Number(parts[2]);

    if (isNaN(year) || isNaN(month) || isNaN(day)) {
      return new Date();
    }

    return new Date(year, month - 1, day);
  }

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();

    const params = router.getParams() as Record<string, Object>;

    if (params && params['billId'] !== undefined && params['billId'] !== null) {
      this.isEdit = true;
      this.pageTitle = '编辑账单';

      this.editBillId = Number(params['billId']);
      this.amountInput = String(params['amount'] || '');
      this.selectedCategory = params['category'] as CategoryType;

      const oldDate = String(params['date'] || '');
      if (oldDate.length > 0) {
        this.date = oldDate;
      } else {
        this.date = this.formatDate(new Date());
      }

      this.remark = String(params['remark'] || '');

      console.info(`Edit bill page opened, billId=${this.editBillId}, date=${this.date}`);
    } else {
      this.isEdit = false;
      this.editBillId = -1;
      this.pageTitle = '记一笔';
      this.date = this.formatDate(new Date());
      this.remark = '';
    }
  }

  build() {
    Scroll() {
      Column() {
        // 标题栏
        Row() {
          Button('取消')
            .backgroundColor('#00000000')
            .fontColor('#666666')
            .onClick(() => {
              router.back();
            })

          Text(this.pageTitle)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button('保存')
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.saveBill();
            })
        }
        .width('90%')
        .height(48)
        .margin({ top: 8 })

        // 金额输入
        Column() {
          Text('金额')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '0.00',
            text: this.amountInput
          })
            //.type(InputType.Number)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .height(60)
            .border({
              width: {
                bottom: this.amountError ? 2 : 1
              },
              color: this.amountError ? '#F44336' : '#E0E0E0'
            })
            .onChange((value: string) => {
              this.amountInput = value;

              if (!value || value.trim().length === 0) {
                this.amountError = '';
                return;
              }

              if (!CurrencyUtil.isValidAmount(value)) {
                this.amountError = '请输入有效金额（最多两位小数）';
              } else {
                this.amountError = '';
              }
            })

          if (this.amountError) {
            Text(this.amountError)
              .fontSize(12)
              .fontColor('#F44336')
              .margin({ top: 4 })
          }
        }
        .width('90%')
        .margin({ top: 24 })

        // 分类选择
        Column() {
          Text('分类')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Grid() {
            ForEach(this.categoryArray, (category: CategoryType) => {
              GridItem() {
                Text(category)
                  .fontSize(14)
                  .padding({
                    left: 12,
                    right: 12,
                    top: 6,
                    bottom: 6
                  })
                  .borderRadius(16)
                  .backgroundColor(this.selectedCategory === category ? '#4CAF50' : '#F5F5F5')
                  .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#333333')
              }
              .onClick(() => {
                this.selectedCategory = category;
              })
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(8)
          .width('100%')
        }
        .width('90%')
        .margin({ top: 24 })

        // 日期选择
        Column() {
          Text('日期')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          DatePicker({
            start: new Date('2000-01-01'),
            end: new Date('2100-12-31'),
            selected: this.parseDate(this.date)
          })
            .onChange((value: DatePickerResult) => {
              this.date = `${value.year}-${String(value.month + 1).padStart(2, '0')}-${String(value.day).padStart(2, '0')}`;
            })

          Text(`当前选择日期：${this.date}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('90%')
        .margin({ top: 24 })

        // 备注输入
        Column() {
          Text('备注')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          TextInput({
            placeholder: '添加备注（可选）',
            text: this.remark
          })
            .maxLength(50)
            .fontSize(14)
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({
              left: 12,
              right: 12
            })
            .onChange((value: string) => {
              this.remark = value;
            })
        }
        .width('90%')
        .margin({ top: 24 })

        if (this.isEdit) {
          Button('删除账单')
            .width('60%')
            .height(48)
            .fontSize(16)
            .backgroundColor('#F44336')
            .borderRadius(24)
            .margin({ top: 32 })
            .onClick(async () => {
              if (this.editBillId < 0) {
                this.amountError = '账单编号错误，无法删除';
                return;
              }

              await this.viewModel.deleteBill(this.editBillId);
              router.back();
            })
        }

        Blank()
          .height(40)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  async saveBill(): Promise<void> {
    if (!this.amountInput || this.amountInput.trim().length === 0) {
      this.amountError = '请输入金额';
      return;
    }

    if (!CurrencyUtil.isValidAmount(this.amountInput)) {
      this.amountError = '请输入有效金额（最多两位小数）';
      return;
    }

    if (!this.date || this.date.trim().length === 0) {
      this.amountError = '请选择日期';
      return;
    }

    try {
      let success = false;

      if (this.isEdit) {
        if (this.editBillId < 0) {
          this.amountError = '账单编号错误，无法修改';
          return;
        }

        success = await this.viewModel.updateBill(
          this.editBillId,
          this.amountInput.trim(),
          this.selectedCategory,
          this.date.trim(),
          this.remark.trim()
        );
      } else {
        success = await this.viewModel.addBill(
          this.amountInput.trim(),
          this.selectedCategory,
          this.date.trim(),
          this.remark.trim()
        );
      }

      if (success) {
        router.back();
      } else {
        this.amountError = '保存失败，请重试';
      }
    } catch (error) {
      console.error('Error saving bill:', error);
      this.amountError = '保存失败，请重试';
    }
  }
}