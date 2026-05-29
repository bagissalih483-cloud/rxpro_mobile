# 46L Muhasebe Cloud Function Kontratı

Bu aşamada function kodu deploy edilmez. Sadece endpoint mantığı sabitlenir.

## Callable fonksiyon adayları

- `accountingCreateManualSale`
- `accountingCollectPayment`
- `accountingCreateExpense`
- `accountingUpdateExpense`
- `accountingCreateRecurringExpense`
- `accountingGenerateReport`

## accountingCreateManualSale

Girdi:
- businessId
- customerId?
- customerPhone?
- customerName?
- saleType
- items[]
- totalAmountKurus
- paidAmountKurus
- dueDate?
- installmentPlan?
- closeAtCollectedAmount
- paymentMethod
- note?

Ãœretilecek kayıtlar:
- accountingSales
- accountingPayments, tahsilat varsa
- accountingReceivables, kalan alacak varsa
- bireysel kullanıcı geçmişi, customerId varsa

## accountingCreateExpense

Girdi:
- businessId
- category
- title
- amountKurus
- paymentMethod
- paid/unpaid
- expenseDate
- recurring?
- recurrencePeriod?
- nextDate?
- note?

Ãœretilecek kayıtlar:
- accountingExpenses
- accountingRecurringExpenses, tekrar varsa

## Güvenlik

Her fonksiyon:
- auth.uid kontrolü
- business membership kontrolü
- permission kontrolü
- server timestamp
- immutable audit fields
ile çalışmalıdır.