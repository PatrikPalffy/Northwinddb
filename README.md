# **ETL proces datasetu NorthWind**

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z **Northwind** datasetu.Projekt sa zameriava na preskúmanie správania zákazníkov a ich nákupných preferencií na základe objednávok, produktov a demografických údajov zákazníkov. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrík, ako sú trendy predaja, preferované kategórie produktov a geografické rozloženie zákazníkov.

---
## **1. Úvod a popis zdrojových dát**
Cieľom semestrálneho projektu je analyzovať dáta týkajúce sa zákazníkov, produktov a ich objednávok. Táto analýza umožňuje identifikovať trendy v nákupných preferenciách, najpopulárnejšie produkty a správanie zákazníkov.

Zdrojové dáta pochádzajú z Kaggle datasetu dostupného [tu]([https://www.kaggle.com/datasets/cleveranjosqlik/csv-northwind-database]). Dataset obsahuje osem hlavných tabuliek:
- `orders`
- `supliers`
- `products`
- `order_details`
- `customers`
- `employees`

Účelom ETL procesu bolo tieto dáta pripraviť, transformovať a sprístupniť pre viacdimenzionálnu analýzu.

---
### **1.1 Dátová architektúra**

### **ERD diagram**
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na **entitno-relačnom diagrame (ERD)**:

<p align="center">
  <img src="https://github.com/PatrikPalffy/Northwinddb/blob/main/erd_Schema_Palffy.png" alt="ERD Schema">
  <br>
  <em>Obrázok 1 Entitno-relačná schéma NorthWind</em>
</p>

---
## **2 Dimenzionálny model**

Navrhnutý bol **hviezdicový model (star schema)**, pre efektívnu analýzu kde centrálny bod predstavuje faktová tabuľka **`fact_order_details`**, ktorá je prepojená s nasledujúcimi dimenziami:
- **`dim_customer`**: Obsahuje podrobné informácie o zákazníkoch, ako sú meno kontaktnej osoby, adresa, mesto, región, krajina a telefónne číslo.
- **`dim_product`**: Obsahuje podrobné údaje o produktoch, ako názov produktu, kategória, dodávateľ a štandardná cena.
- **`dim_date`**:  Zahrňuje informácie o dátumoch objednávok a expedície, ako sú deň, mesiac, rok a deň v mesiaci.
- **`dim_employee`**: Obsahuje informácie o zamestnancoch, ako sú mená, miesto práce (mesto, krajina) a poštové smerovacie číslo.

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami, čo zjednodušuje pochopenie a implementáciu modelu.

<p align="center">
  <img src="https://github.com/PatrikPalffy/Northwinddb/blob/main/star_schema_Palffy.png" alt="Star Schema">
  <br>
  <em>Obrázok 2 Schéma hviezdy pre NorthWind</em>
</p>

---
## **3. ETL proces v Snowflake**
ETL proces pozostával z troch hlavných fáz: `extrahovanie` (Extract), `transformácia` (Transform) a `načítanie` (Load). Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta zo staging vrstvy do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

---
### **3.1 Extract (Extrahovanie dát)**
Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do Snowflake prostredníctvom interného stage úložiska s názvom `FICNH_NW_STAGE`. Stage v Snowflake slúži ako dočasné úložisko na import alebo export dát. Vytvorenie stage bolo zabezpečené príkazom:

#### Príklad kódu:
```sql
CREATE OR REPLACE STAGE FICNH_NW_STAGE;
```
Do stage boli následne nahraté súbory obsahujúce údaje o knihách, používateľoch, hodnoteniach, zamestnaniach a úrovniach vzdelania. Dáta boli importované do staging tabuliek pomocou príkazu `COPY INTO`. Pre každú tabuľku sa použil podobný príkaz:

```sql
COPY INTO customers_staging
FROM @FICNH_NW_STAGE/customers.csv
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);
```

V prípade nekonzistentných záznamov bol použitý parameter `ON_ERROR = 'CONTINUE'`, ktorý zabezpečil pokračovanie procesu bez prerušenia pri chybách.

---
### **3.1 Transfor (Transformácia dát)**

V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

Dimenzia `dim_date` bola navrhnutá na poskytovanie kontextu pre faktovú tabuľku prostredníctvom údajov o dátumoch. Táto dimenzia slúži na rozklad dát na jemnejšie časové jednotky pre analýzy ako trendy predaja alebo sezónnosť.
```sql
CREATE OR REPLACE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    month INT,
    day_of_month INT,
    day_name VARCHAR(45),
    month_name VARCHAR(45)
);

```
Táto dimenzia je štruktúrovaná pre podrobné časové analýzy, ako sú trendy predaja podľa dní, mesiacov alebo rokov. Z hľadiska SCD (Slowly Changing Dimensions) je táto dimenzia klasifikovaná ako SCD Typ 0, čo znamená, že existujúce záznamy sú nemenné a uchovávajú statické informácie o dátumoch.

V prípade, že by bolo potrebné sledovať zmeny súvisiace s odvodenými atribútmi (napríklad pracovné dni vs. sviatky), dimenzia `dim_date` by mohla byť preklasifikovaná na:

SCD Typ 1: Kde by sa existujúce hodnoty aktualizovali na základe zmien (napr. preklasifikovanie dňa na sviatok).
SCD Typ 2: Kde by sa uchovávala história zmien, aby bolo možné analyzovať dáta v kontexte historických klasifikácií (napr. pracovné dni v minulosti).

```sql
CREATE OR REPLACE TABLE dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id INT NOT NULL,
    company_name VARCHAR(45),
    contact_name VARCHAR(45),
    contact_title VARCHAR(45),
    address VARCHAR(45),
    city VARCHAR(45),
    region VARCHAR(45),
    postal_code VARCHAR(45),
    country VARCHAR(45),
    phone VARCHAR(45)
);
```
Podobne, `dim_customer` obsahuje údaje o zákazníkoch. Táto dimenzia je navrhnutá ako SCD Typ 0, pretože údaje o zákazníkoch, ako je meno kontaktnej osoby alebo adresa, sú považované za statické a nemenia sa v rámci tohto modelu.

Faktová tabuľka `fact_order_details` obsahuje záznamy o objednávkach a je prepojená so všetkými dimenziami. Táto tabuľka zahŕňa kľúčové metriky a informácie potrebné na analýzu obchodných transakcií.
```sql
CREATE OR REPLACE TABLE fact_order_details (
    fact_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT,
    quantity FLOAT,
    unit_price FLOAT,
    discount FLOAT,
    extended_price FLOAT,
    order_date_key INT,
    shipped_date_key INT,
    customer_key INT,
    employee_key INT,
    shipper_key INT,
    product_key INT
);
```

---
### **3.3 Load (Načítanie dát)**

ETL proces v Snowflake umožnil spracovanie pôvodných dát z .csv formátu do viacdimenzionálneho modelu typu hviezda. Tento proces zahŕňal čistenie, obohacovanie a reorganizáciu údajov. Výsledný model umožňuje analýzu objednávok, zákazníckych preferencií a výkonnosti produktov či zamestnancov, pričom poskytuje základ pre vytváranie vizualizácií a reportov o obchodných trendoch a metrikách.

---
## **4 Vizualizácia dát**

Dashboard obsahuje `5 vizualizácií`, ktoré poskytujú prehľad o kľúčových metrikách a trendoch týkajúcich sa objednávok, zákazníkov, prepravcov a produktov. Tieto vizualizácie umožňujú lepšie pochopiť správanie zákazníkov a výkonnosť procesov.

<p align="center">
  <img src="https://github.com/PatrikPalffy/Northwinddb/blob/main/5visualizations-NWdb.png" alt="ERD Schema">
  <br>
  <em>Obrázok 3 Dashboard NorthWind datasetu</em>
</p>

---
### **Graf 1: Number of customers per country**
Táto vizualizácia zobrazuje počet zákazníkov podľa krajiny. Umožňuje identifikovať geografické oblasti s najväčším počtom zákazníkov a získať prehľad o rozložení používateľov podľa regiónov. Tieto informácie môžu byť užitočné na optimalizáciu marketingových kampaní, prispôsobenie ponuky produktov alebo služieb, alebo identifikáciu trhov, ktoré si zaslúžia väčšiu pozornosť.

```sql
SELECT 
    Country AS country,
    COUNT(*) AS appearance
FROM 
    customers_staging
GROUP BY 
    Country
ORDER BY 
    appearance DESC;

```
---
### **Graf 2: Total Quantity Ordered per Product**
Graf znázorňuje rozdiely v počte objednaných produktov podľa jednotlivých produktov. Z údajov je zrejmé, že niektoré produkty sú objednávané častejšie než iné, čo poskytuje prehľad o preferenciách zákazníkov. Rozdiely medzi jednotlivými produktmi môžu pomôcť identifikovať populárne položky, ktoré si zaslúžia väčšiu marketingovú pozornosť.

```sql
SELECT 
    ProductID AS product_id,
    SUM(Quantity) AS total_quantity
FROM 
    order_details_staging
GROUP BY 
    ProductID
ORDER BY 
    ProductID;
```
---
### **Graf 3: Top Shippers by Number of Orders **
Graf zobrazuje najväčších dodávateľov podľa počtu objednávok, ktoré odoslali. Z vizualizácie je zrejmé, ktorí dodávatelia majú najväčší objem objednávok, čo môže pomôcť pri identifikácii kľúčových partnerov a optimalizácii logistických procesov. 

```sql
SELECT 
    s.CompanyName AS shipper_name,
    COUNT(o.OrderID) AS total_orders
FROM 
    orders_staging o
JOIN 
    suppliers_staging s ON o.ShipVia = s.SupplierID
GROUP BY 
    s.CompanyName
ORDER BY 
    total_orders DESC
LIMIT 10;
```
---
### **Graf 4: Number of Orders Shipped by Country**
Tabuľka zobrazuje, ako sú objednávky rozdelené podľa jednotlivých krajín. Z údajov je zrejmé, ktoré krajiny zaznamenali najväčší počet odoslaných objednávok. Tento graf pomáha identifikovať geografické oblasti s najvyšším objemom objednávok, čo môže byť cenné pri analýze trhov a optimalizácii distribučných procesov.
```sql
SELECT 
    Country AS country,
    COUNT(*) AS appearance
FROM 
    customers_staging
GROUP BY 
    Country
ORDER BY 
    appearance DESC;
```
---
### **Graf 5: Average Order Value by Customer**
Tento graf poskytuje informácie o priemerných hodnotách objednávok podľa jednotlivých zákazníkov. Umožňuje analyzovať, ktorí zákazníci vygenerovali najvyššiu priemernú hodnotu objednávok, čo môže byť užitočné pri identifikácii kľúčových zákazníkov a optimalizácii predajných stratégií.

```sql
SELECT 
    c.CompanyName AS customer_name,
    AVG(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS avg_order_value
FROM 
    order_details_staging od
JOIN 
    orders_staging o ON od.OrderID = o.OrderID
JOIN 
    customers_staging c ON o.CustomerID = c.CustomerID
GROUP BY 
    c.CompanyName
ORDER BY 
    avg_order_value DESC;
```


Dashboard poskytuje komplexný pohľad na dáta, pričom zodpovedá dôležité otázky týkajúce sa obchodného správania a zákazníckych preferencií. Vizualizácie umožňujú jednoduchú interpretáciu dát a môžu byť využité na optimalizáciu obchodných stratégií, marketingových kampaní, a logistiky.

---

**Autor:** Patrik Pálffy
