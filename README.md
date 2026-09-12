# 📊 Signature P&L Suite

ระบบบริหารบัญชี สรุปรายรับ-รายจ่าย 3 ร้านค้า และจัดสรรกำไร 50/50 พัฒนาด้วย **Flutter Web** เชื่อมต่อฐานข้อมูล **Supabase Cloud** แบบ Real-time และดึงข้อมูลต้นทุนเงินเดือนพนักงานจาก **Signature Payroll** โดยอัตโนมัติ

---

## 🏢 ข้อมูลร้านค้า (3 Stores)
1. **Signature สาขา Big Shop**
2. **Signature สาขา Cabana**
3. **Seaside**

---

## ⚖️ สูตรการคำนวณกำไรขาดทุนและการจัดสรรผลประโยชน์

1. **รายได้รวม (Total Revenue):**
   * ผลรวมยอดขายประจำวันของทั้ง 3 ร้านค้า (Big Shop, Cabana, Seaside)
2. **หัก รายจ่ายดำเนินงานทั่วไป (Operating Expenses):**
   * ค่าของสด, วัตถุดิบ, ค่าเช่า, ค่าน้ำไฟ, ของใช้สิ้นเปลือง ฯลฯ
3. **หัก ต้นทุนพนักงานหน้าร้าน (Staff Labor Cost):**
   * ดึงสดจากระบบ **Signature Payroll** ผ่าน Supabase Cloud (`payroll_summary` และ `payroll_adjustments`)
4. **หัก เงินเดือนประจำตำแหน่งผู้บริหาร (รวม ฿85,000 / เดือน):**
   * 🟣 **Nantaporn:** ฿30,000 / เดือน *(ดูแลบัญชีกองกลางหมุนเวียน)*
   * 🔵 **Thayakorn:** ฿30,000 / เดือน
   * 🟢 **Churntawan:** ฿25,000 / เดือน
   * 🟠 **Kanthong:** ฿0 / เดือน
5. **= กำไรสุทธิสำหรับจัดสรร (Net Distributable Profit):**
   * แบ่งปันผลกำไรตามสัดส่วน **50 / 50**:
     * **กลุ่มที่ 1 (50%):** สำหรับ **Nantaporn** & **Thayakorn** (คนละ 25%)
     * **กลุ่มที่ 2 (50%):** สำหรับ **Churntawan** & **Kanthong** (คนละ 25%)
6. **ยอดเงินรับสุทธิของแต่ละคน (Net Payout):**
   $$\text{เงินรับสุทธิ} = \text{เงินสำรองจ่ายที่ควักไป (เคลียร์คืน)} + \text{เงินเดือนประจำตำแหน่ง} + \text{ส่วนแบ่งกำไรสุทธิ}$$

---

## 🚀 การ Deploy สู่ GitHub Pages

โปรเจกต์นี้รองรับ CI/CD ผ่าน GitHub Actions อัตโนมัติ:
1. สร้าง Remote Repository บน GitHub ภายใต้ชื่อ **`signature_accounting_app`** (บัญชี: `Churntawan`)
2. Push โค้ดขึ้น branch `master` หรือ `main`
3. GitHub Actions จะทำการ Build และ Deploy ไปยัง:
   👉 **`https://churntawan.github.io/signature_accounting_app/`**
