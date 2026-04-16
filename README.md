# green_app

Ung dung Flutter theo huong Green lifestyle, su dung Firebase Auth + Firestore + Storage.

## Tinh nang chinh

- Dashboard mau trang-xanh sang, dong bo App Theme.
- Header Home co icon thong bao va avatar; bam avatar de vao trang Profile.
- Bottom navigation da loai bo muc Admin nhu yeu cau giao dien nguoi dung.
- Trang Profile hien thi thong tin ca nhan va diem (tong diem, diem tuan, diem thang).
- Ho tro doi avatar tu thu vien anh, upload len Firebase Storage, luu URL vao Firestore.

## Firebase profile fields

Document nguoi dung trong collection users co the gom:

- uid
- email
- fullName
- city
- district
- avatarUrl
- totalPoints
- weeklyPoints
- monthlyPoints

Neu cac truong diem chua co, app se hien thi gia tri mac dinh de tranh trang thai trong.

## Chay du an

1. Cai dependencies:
	flutter pub get
2. Chay app:
	flutter run
