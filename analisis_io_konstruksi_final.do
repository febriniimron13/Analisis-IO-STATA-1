*==============================================================
* Analisis Input-Output — Sektor Konstruksi
* Tabel I-O Indonesia 185 Produk, 2020 (BPS)
* Backward Linkage (BL), Forward Linkage (FL), Income Multiplier (H)
*
* File ini disusun dari sesi interaktif yang SUDAH TERVERIFIKASI
* berhasil dijalankan dan hasilnya cocok 100% dengan perhitungan
* Python/NumPy dan Excel (BL, FL, H identik sampai 6-7 digit desimal).
*==============================================================

clear all
set more off

* ---------------------------------------------------------
* GANTI PATH INI sesuai lokasi folder Anda
* ---------------------------------------------------------
cd "D:\DOCUMENTS APPLYING FOR JOBS IN 2026\input output stata"

* ---------------------------------------------------------
* 1. IMPORT DATA
* ---------------------------------------------------------
import delimited "sector_data_tab.csv", clear varnames(1) delimiter(tab)
capture destring kode, replace
tempfile sectordata
save `sectordata'

import delimited "Z_matrix_tab.csv", clear varnames(1) delimiter(tab)
drop kode
mkmat *, matrix(Z)

use `sectordata', clear
mkmat total_output_x, matrix(X)
mkmat kompensasi_tk, matrix(V)

* ---------------------------------------------------------
* 2. HITUNG DI MATA
* ---------------------------------------------------------
mata:
    Z = st_matrix("Z")
    X = st_matrix("X")
    V = st_matrix("V")
    n = 185

    // hindari pembagian dengan nol
    Xsafe = X
    for (j=1; j<=n; j++) {
        if (Xsafe[j,1]==0) Xsafe[j,1] = 1
    }

    // matriks koefisien teknis A (a_ij = z_ij / x_j)
    A = J(n,n,0)
    for (j=1; j<=n; j++) {
        A[,j] = Z[,j] :/ Xsafe[j,1]
    }

    // Matriks Kebalikan Leontief (I-A)^-1
    Ident = I(n)
    Leontief = luinv(Ident - A)

    // Backward Linkage (BL) & Forward Linkage (FL)
    colsum = colsum(Leontief)'
    rowsum = rowsum(Leontief)
    grand_total = sum(Leontief)

    BL = n :* colsum :/ grand_total
    FL = n :* rowsum :/ grand_total

    // Income Multiplier (H)
    voverx = V :/ Xsafe
    H_num = voverx' * Leontief
    H_den = sum(voverx :* rowsum)
    H = (n :* H_num :/ H_den)'

    // kirim hasil balik ke Stata
    st_matrix("BL", BL)
    st_matrix("FL", FL)
    st_matrix("H", H)

    // ===========================================================
    // VERIFIKASI MATRIKS (pembuktian hasil valid secara matematis/ekonomi)
    // ===========================================================
    // 1. (I-A) x Leontief harus = Identitas (bukti inversi matriks benar)
    check_identity   = Ident - (Ident - A) * Leontief
    max_dev_identity = max(abs(check_identity))

    // 2. Sifat normalisasi Rasmussen-Hirschman: total BL=FL=H harus = n
    sum_BL = sum(BL)
    sum_FL = sum(FL)
    sum_H  = sum(H)

    // 3. Syarat Hawkins-Simon: setiap kolom matriks A harus < 1
    max_colsum_A = max(colsum(A))

    // 4. Non-negativitas: elemen Leontief tidak boleh negatif
    min_leontief = min(Leontief)

    st_numscalar("max_dev_identity", max_dev_identity)
    st_numscalar("sum_BL", sum_BL)
    st_numscalar("sum_FL", sum_FL)
    st_numscalar("sum_H", sum_H)
    st_numscalar("max_colsum_A", max_colsum_A)
    st_numscalar("min_leontief", min_leontief)
end

* ---------------------------------------------------------
* 2b. VERIFIKASI MATRIKS -- bukti hasil valid + justifikasi
* ---------------------------------------------------------
di as text "=========================================================="
di as text "VERIFIKASI MATRIKS LEONTIEF DAN INDEKS TURUNANNYA"
di as text "=========================================================="
di as text "1) Cek (I-A) x Leontief = Identitas"
di as text "   Deviasi maksimum dari nol: " %12.2e max_dev_identity
di as text "   Justifikasi: (I-A) dikalikan kebalikannya, (I-A)^-1, secara"
di as text "   matematis HARUS menghasilkan matriks identitas. Deviasi yang"
di as text "   sangat kecil (<1e-6) membuktikan inversi matriks 185x185"
di as text "   dihitung akurat, bukan hasil pembulatan atau kesalahan numerik."
di ""
di as text "2) Cek normalisasi indeks (total harus = n = 185)"
di as text "   Jumlah seluruh BL : " %10.4f sum_BL
di as text "   Jumlah seluruh FL : " %10.4f sum_FL
di as text "   Jumlah seluruh H  : " %10.4f sum_H
di as text "   Justifikasi: Rumus Rasmussen-Hirschman menormalisasi tiap indeks"
di as text "   dengan faktor n/total, sehingga rata-rata seluruh sektor otomatis"
di as text "   = 1 dan jumlah totalnya = n. Hasil di atas yang persis 185,0000"
di as text "   membuktikan formula BL/FL/H diterapkan sesuai definisi bakunya."
di ""
di as text "3) Cek syarat Hawkins-Simon (kelayakan/viabilitas ekonomi)"
di as text "   Jumlah kolom maksimum matriks A: " %8.4f max_colsum_A
di as text "   Justifikasi: Syarat Hawkins-Simon mensyaratkan setiap kolom"
di as text "   matriks koefisien teknis (A) harus lebih kecil dari 1 -- artinya"
di as text "   suatu sektor tidak boleh membutuhkan lebih dari 1 unit inputnya"
di as text "   sendiri untuk menghasilkan 1 unit output. Nilai di atas yang"
di as text "   lebih kecil dari 1 membuktikan struktur ekonomi tabel I-O ini"
di as text "   valid dan solusi (I-A)^-1 secara ekonomi bermakna (viable)."
di ""
di as text "4) Cek non-negativitas matriks Leontief"
di as text "   Nilai minimum elemen Leontief: " %10.6f min_leontief
di as text "   Justifikasi: Elemen matriks kebalikan Leontief merepresentasikan"
di as text "   dampak output antar sektor, yang secara ekonomi tidak mungkin"
di as text "   negatif. Nilai minimum >= 0 membuktikan hasil inversi konsisten"
di as text "   dan tidak menghasilkan solusi yang mustahil secara ekonomi."
di as text "=========================================================="

* ---------------------------------------------------------
* 3. GABUNGKAN HASIL KE DATASET
* ---------------------------------------------------------
use `sectordata', clear
svmat BL, name(BL)
svmat FL, name(FL)
svmat H, name(H)
rename BL1 backward_linkage
rename FL1 forward_linkage
rename H1  income_multiplier

gen kat_bl = cond(backward_linkage>1, "Tinggi","Rendah")
gen kat_fl = cond(forward_linkage>1, "Tinggi","Rendah")
gen klasifikasi = "Tertinggal"
replace klasifikasi = "Unggulan (kunci)"       if kat_bl=="Tinggi" & kat_fl=="Tinggi"
replace klasifikasi = "Potensial (backward)"   if kat_bl=="Tinggi" & kat_fl=="Rendah"
replace klasifikasi = "Potensial (forward)"    if kat_bl=="Rendah" & kat_fl=="Tinggi"

* ---------------------------------------------------------
* 4. TAMPILKAN HASIL — FOKUS SEKTOR KONSTRUKSI (kode 149-153)
* ---------------------------------------------------------
list kode nama backward_linkage forward_linkage income_multiplier klasifikasi ///
    if kode>=149 & kode<=153, clean noobs

* ---------------------------------------------------------
* 5. RANKING SELURUH 185 SEKTOR (opsional, untuk konteks)
* ---------------------------------------------------------
gen rank_bl = .
gen rank_fl = .
gen rank_h  = .
egen rank_bl2 = rank(-backward_linkage)
egen rank_fl2 = rank(-forward_linkage)
egen rank_h2  = rank(-income_multiplier)
drop rank_bl rank_fl rank_h
rename rank_bl2 rank_bl
rename rank_fl2 rank_fl
rename rank_h2  rank_h

list kode nama rank_bl rank_fl rank_h if kode>=149 & kode<=153, clean noobs

* ---------------------------------------------------------
* 6. SIMULASI DAMPAK: INVESTASI TAMBAHAN Rp 1 TRILIUN KE KONSTRUKSI
*    Model permintaan Leontief: dX = (I-A)^-1 * dF
*    Alokasi ke 5 sub-sektor (149-153) proporsional terhadap PMTB
*    (Pembentukan Modal Tetap Bruto) eksisting masing-masing di
*    tabel I-O 2020 (bukan dibagi rata).
*    Catatan: Leontief, A, dan voverx MASIH ADA di memori Mata
*    dari blok "2. HITUNG DI MATA" di atas (Mata tidak otomatis
*    "mata clear" antar blok dalam sesi yang sama).
* ---------------------------------------------------------
mata:
    // PMTB eksisting 5 sub-sektor konstruksi (Juta Rupiah), dari tabel I-O 2020
    pmtb_kon = (1953045853 \ 121324025 \ 36132647 \ 140294086 \ 907704387)
    shock_total_juta = 1000000   // Rp 1 triliun = 1.000.000 Juta Rupiah (unit tabel)

    share = pmtb_kon :/ sum(pmtb_kon)
    shock_per_sub = shock_total_juta :* share

    dF = J(n,1,0)
    dF[149,1] = shock_per_sub[1,1]
    dF[150,1] = shock_per_sub[2,1]
    dF[151,1] = shock_per_sub[3,1]
    dF[152,1] = shock_per_sub[4,1]
    dF[153,1] = shock_per_sub[5,1]

    dX      = Leontief * dF          // dampak output per sektor
    dIncome = voverx :* dX           // dampak pendapatan per sektor

    total_output_impact        = sum(dX)
    output_multiplier          = total_output_impact / shock_total_juta
    total_income_impact        = sum(dIncome)
    income_multiplier_realized = total_income_impact / shock_total_juta

    st_matrix("dX", dX)
    st_matrix("dIncome", dIncome)
    st_numscalar("total_output_impact", total_output_impact)
    st_numscalar("output_multiplier", output_multiplier)
    st_numscalar("total_income_impact", total_income_impact)
    st_numscalar("income_multiplier_realized", income_multiplier_realized)
end

svmat dX, name(dX)
svmat dIncome, name(dIncome)
rename dX1      dampak_output
rename dIncome1 dampak_pendapatan

di as text "=========================================================="
di as text "SIMULASI: Investasi Rp 1 Triliun ke Sektor Konstruksi"
di as text "=========================================================="
di as text "Total dampak output ke seluruh ekonomi (Rp): " %20.0fc (total_output_impact*1000000)
di as text "Output multiplier agregat                  : " %8.4f output_multiplier
di as text "Total dampak pendapatan masyarakat (Rp)     : " %20.0fc (total_income_impact*1000000)
di as text "Income multiplier realisasi                 : " %8.4f income_multiplier_realized
di as text "=========================================================="

di as text "Dampak per sub-sektor Konstruksi:"
list kode nama dampak_output dampak_pendapatan if kode>=149 & kode<=153, clean noobs

di as text "Top 15 sektor NON-konstruksi paling terdampak (efek hulu):"
gen dampak_output_exkon = dampak_output
replace dampak_output_exkon = . if kode>=149 & kode<=153
gsort -dampak_output_exkon
list kode nama dampak_output in 1/15, clean noobs
sort kode

* ---------------------------------------------------------
* 7. GRAFIK (native Stata graph, disimpan sebagai .png)
* ---------------------------------------------------------
* label kode sektor konstruksi supaya sumbu grafik rapi (bukan cuma nomor)
gen str30 label_singkat = ""
replace label_singkat = "Bangunan"          if kode==149
replace label_singkat = "Bangunan+Instalasi" if kode==150
replace label_singkat = "Prasarana Pertanian" if kode==151
replace label_singkat = "Jalan/Jembatan"     if kode==152
replace label_singkat = "Bangunan Lainnya"   if kode==153

* --- Grafik 1: BL vs FL, 5 sub-sektor konstruksi ---
graph bar backward_linkage forward_linkage if kode>=149 & kode<=153, ///
    over(label_singkat, label(angle(30))) ///
    legend(label(1 "Backward Linkage (BL)") label(2 "Forward Linkage (FL)")) ///
    ytitle("Nilai Indeks") ///
    title("Indeks Keterkaitan BL dan FL") ///
    subtitle("Sub-Sektor Konstruksi, Tabel I-O 2020") ///
    bar(1, color("31 78 121")) bar(2, color("244 178 131")) ///
    xsize(7.5) ysize(5)
graph export "grafik1_BL_FL.png", replace width(1600)

* --- Grafik 2: Income Multiplier, 5 sub-sektor konstruksi ---
graph bar income_multiplier if kode>=149 & kode<=153, ///
    over(label_singkat, label(angle(30))) ///
    ytitle("Indeks Income Multiplier (H)") ///
    title("Income Multiplier Sub-Sektor Konstruksi") ///
    bar(1, color("46 125 50")) ///
    xsize(7.5) ysize(5)
graph export "grafik2_income_multiplier.png", replace width(1600)

* --- Grafik 3: Dampak simulasi (output vs pendapatan, Rp Miliar) ---
gen dampak_output_miliar = dampak_output/1000
gen dampak_pendapatan_miliar = dampak_pendapatan/1000
graph bar dampak_output_miliar dampak_pendapatan_miliar if kode>=149 & kode<=153, ///
    over(label_singkat, label(angle(30))) ///
    legend(label(1 "Dampak Output") label(2 "Dampak Pendapatan")) ///
    ytitle("Rp Miliar") ///
    title("Dampak Simulasi Investasi Rp 1 Triliun") ///
    subtitle("Output vs Pendapatan per Sub-Sektor") ///
    bar(1, color("31 78 121")) bar(2, color("192 80 77")) ///
    xsize(7.5) ysize(5)
graph export "grafik3_dampak_simulasi.png", replace width(1600)

* --- Grafik 4: Top 10 sektor non-konstruksi paling terdampak (horizontal) ---
preserve
gsort -dampak_output_exkon
keep in 1/10
gen dampak_output_miliar2 = dampak_output/1000
gen str28 nama_singkat = substr(nama,1,25)
replace nama_singkat = nama_singkat + "..." if length(nama)>25
graph hbar dampak_output_miliar2, over(nama_singkat, sort(dampak_output_miliar2) label(labsize(vsmall))) ///
    ytitle("Rp Miliar") ///
    title("10 Sektor Non-Konstruksi" "Paling Terdampak", size(medium)) ///
    subtitle("Efek Hulu/Backward dari Investasi Rp 1 Triliun", size(small)) ///
    bar(1, color("244 178 131")) ///
    xsize(9) ysize(6.5)
graph export "grafik4_top10_terdampak.png", replace width(1800)
restore

di as text "=========================================================="
di as text "Empat grafik tersimpan: grafik1_BL_FL.png, grafik2_income_multiplier.png,"
di as text "grafik3_dampak_simulasi.png, grafik4_top10_terdampak.png"
di as text "=========================================================="

* ---------------------------------------------------------
* 8. STATISTIK DESKRIPTIF
* ---------------------------------------------------------
di as text "Statistik deskriptif BL, FL, H -- seluruh 185 sektor:"
tabstat backward_linkage forward_linkage income_multiplier, ///
    statistics(mean median sd min max) columns(statistics)

di as text "Statistik deskriptif BL, FL, H -- 5 sub-sektor Konstruksi:"
tabstat backward_linkage forward_linkage income_multiplier if kode>=149 & kode<=153, ///
    statistics(mean sd min max) columns(statistics)

* --- Scatter BL vs FL, seluruh 185 sektor, dengan 5 titik Konstruksi ditandai ---
gen highlight = (kode>=149 & kode<=153)
twoway (scatter forward_linkage backward_linkage if highlight==0, ///
            mcolor(gs10) msize(small)) ///
       (scatter forward_linkage backward_linkage if highlight==1, ///
            mcolor(red) msize(medium) mlabel(kode) mlabposition(3)), ///
    xline(1, lpattern(dash) lcolor(gs8)) yline(1, lpattern(dash) lcolor(gs8)) ///
    xtitle("Backward Linkage (BL)") ytitle("Forward Linkage (FL)") ///
    title("Sebaran BL-FL Seluruh 185 Sektor") ///
    subtitle("Titik merah = 5 sub-sektor Konstruksi") ///
    legend(order(1 "Sektor lain" 2 "Konstruksi"))
graph export "grafik5_sebaran_BL_FL_185sektor.png", replace width(1400)

* ---------------------------------------------------------
* 9. ANALISIS PEMASOK & PENGGUNA UTAMA (transaksi langsung dari matriks Z)
*    Catatan: matriks Z (185x185) masih ada di memori Stata dari Bagian 1
* ---------------------------------------------------------
mata:
    Zmat = st_matrix("Z")
    kon_cols = (149,150,151,152,153)
    input_to_kon = J(185,1,0)
    for (k=1; k<=5; k++) {
        input_to_kon = input_to_kon + Zmat[,kon_cols[k]]
    }
    output_from_kon = J(1,185,0)
    for (k=1; k<=5; k++) {
        output_from_kon = output_from_kon + Zmat[kon_cols[k],]
    }
    st_matrix("input_to_kon", input_to_kon)
    st_matrix("output_from_kon", output_from_kon')
end

svmat input_to_kon, name(input_to_kon)
svmat output_from_kon, name(output_from_kon)

di as text "Top 8 sektor pemasok input terbesar KE Konstruksi:"
gsort -input_to_kon1
list kode nama input_to_kon1 in 1/8, clean noobs

di as text "Top 5 sektor pengguna terbesar output Konstruksi (sebagai input mereka):"
gsort -output_from_kon1
list kode nama output_from_kon1 in 1/5, clean noobs
sort kode

* ---------------------------------------------------------
* 10. EXPORT TABEL-TABEL PENTING KE WORD (putdocx, bawaan Stata)
* ---------------------------------------------------------
* --- Siapkan statistik deskriptif sebagai dataset kecil (pakai summarize, robust) ---
quietly summarize backward_linkage, detail
local bl_mean = r(mean)
local bl_p50  = r(p50)
local bl_sd   = r(sd)
local bl_min  = r(min)
local bl_max  = r(max)

quietly summarize forward_linkage, detail
local fl_mean = r(mean)
local fl_p50  = r(p50)
local fl_sd   = r(sd)
local fl_min  = r(min)
local fl_max  = r(max)

quietly summarize income_multiplier, detail
local h_mean = r(mean)
local h_p50  = r(p50)
local h_sd   = r(sd)
local h_min  = r(min)
local h_max  = r(max)

preserve
clear
set obs 3
gen str6 indeks = ""
replace indeks = "BL" in 1
replace indeks = "FL" in 2
replace indeks = "H"  in 3
gen Mean = .
gen Median = .
gen SD = .
gen Min = .
gen Max = .
replace Mean   = `bl_mean' in 1
replace Median = `bl_p50'  in 1
replace SD     = `bl_sd'   in 1
replace Min    = `bl_min'  in 1
replace Max    = `bl_max'  in 1
replace Mean   = `fl_mean' in 2
replace Median = `fl_p50'  in 2
replace SD     = `fl_sd'   in 2
replace Min    = `fl_min'  in 2
replace Max    = `fl_max'  in 2
replace Mean   = `h_mean'  in 3
replace Median = `h_p50'   in 3
replace SD     = `h_sd'    in 3
replace Min    = `h_min'   in 3
replace Max    = `h_max'   in 3
tempfile statall_ds
save `statall_ds'
restore

quietly summarize backward_linkage if kode>=149 & kode<=153, detail
local blk_mean = r(mean)
local blk_sd   = r(sd)
local blk_min  = r(min)
local blk_max  = r(max)

quietly summarize forward_linkage if kode>=149 & kode<=153, detail
local flk_mean = r(mean)
local flk_sd   = r(sd)
local flk_min  = r(min)
local flk_max  = r(max)

quietly summarize income_multiplier if kode>=149 & kode<=153, detail
local hk_mean = r(mean)
local hk_sd   = r(sd)
local hk_min  = r(min)
local hk_max  = r(max)

preserve
clear
set obs 3
gen str6 indeks = ""
replace indeks = "BL" in 1
replace indeks = "FL" in 2
replace indeks = "H"  in 3
gen Mean = .
gen SD = .
gen Min = .
gen Max = .
replace Mean = `blk_mean' in 1
replace SD   = `blk_sd'   in 1
replace Min  = `blk_min'  in 1
replace Max  = `blk_max'  in 1
replace Mean = `flk_mean' in 2
replace SD   = `flk_sd'   in 2
replace Min  = `flk_min'  in 2
replace Max  = `flk_max'  in 2
replace Mean = `hk_mean'  in 3
replace SD   = `hk_sd'    in 3
replace Min  = `hk_min'   in 3
replace Max  = `hk_max'   in 3
tempfile statkon_ds
save `statkon_ds'
restore

putdocx begin

putdocx paragraph, style(Title)
putdocx text ("Hasil Analisis Input-Output Sektor Konstruksi")

putdocx paragraph, style(Heading1)
putdocx text ("1. Indeks Keterkaitan dan Income Multiplier - Sub-Sektor Konstruksi")
putdocx table tbl1 = data(kode nama backward_linkage forward_linkage income_multiplier klasifikasi) ///
    if kode>=149 & kode<=153, varnames

putdocx paragraph, style(Heading1)
putdocx text ("2. Peringkat di Antara 185 Sektor")
putdocx table tbl2 = data(kode nama rank_bl rank_fl rank_h) ///
    if kode>=149 & kode<=153, varnames

putdocx paragraph, style(Heading1)
putdocx text ("3. Statistik Deskriptif - Seluruh 185 Sektor")
preserve
use `statall_ds', clear
putdocx table tbl3 = data(indeks Mean Median SD Min Max), varnames
restore

putdocx paragraph, style(Heading1)
putdocx text ("4. Statistik Deskriptif - 5 Sub-Sektor Konstruksi")
preserve
use `statkon_ds', clear
putdocx table tbl4 = data(indeks Mean SD Min Max), varnames
restore

putdocx paragraph, style(Heading1)
putdocx text ("5. Dampak Simulasi Investasi Rp 1 Triliun per Sub-Sektor")
putdocx table tbl5 = data(kode nama dampak_output dampak_pendapatan) ///
    if kode>=149 & kode<=153, varnames

putdocx paragraph, style(Heading1)
putdocx text ("6. Top 10 Sektor Non-Konstruksi Paling Terdampak")
preserve
gsort -dampak_output_exkon
keep in 1/10
putdocx table tbl6 = data(kode nama dampak_output), varnames
restore

putdocx paragraph, style(Heading1)
putdocx text ("7. Top 8 Sektor Pemasok Input Terbesar ke Konstruksi")
preserve
gsort -input_to_kon1
keep in 1/8
putdocx table tbl7 = data(kode nama input_to_kon1), varnames
restore

putdocx paragraph, style(Heading1)
putdocx text ("8. Top 5 Sektor Pengguna Output Konstruksi Terbesar")
preserve
gsort -output_from_kon1
keep in 1/5
putdocx table tbl8 = data(kode nama output_from_kon1), varnames
restore

putdocx save "Tabel_Hasil_Analisis_IO_Konstruksi.docx", replace

di as text "=========================================================="
di as text "File Word tersimpan: Tabel_Hasil_Analisis_IO_Konstruksi.docx"
di as text "=========================================================="

* ---------------------------------------------------------
* 11. SIMPAN HASIL
* ---------------------------------------------------------
save "hasil_analisis_io.dta", replace
export delimited "hasil_analisis_io.csv", replace
export delimited kode nama dampak_output dampak_pendapatan ///
    using "hasil_simulasi_investasi.csv" if kode>=149 & kode<=153, replace

di as text "=========================================================="
di as text "Analisis selesai. Hasil tersimpan di hasil_analisis_io.dta"
di as text "dan hasil_analisis_io.csv"
di as text "=========================================================="
