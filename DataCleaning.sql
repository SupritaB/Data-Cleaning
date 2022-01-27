  
  /*      DATA CLEANING IN SQL      */
  -------------------------------------------------------------------------------------------
SELECT * from Portfolio.dbo.NashvilleHousing

 /* 1. STANDARDIZE DATE FORMAT 
	The SaleDate column was in the DateTime format, of which the time looks to unuseful 
	as they are just 00:00:00
	Used the CONVERT function to convert 'SaleDate' from 'datetime' to 'date' type 
	and assigned it to  a new column 'SaleDateConverted'   */
----------------------------------------------------------------------------------------------
select SaleDate from Portfolio.dbo.NashvilleHousing

 alter table Portfolio.dbo.NashvilleHousing
  add SaleDateConverted Date;

  update Portfolio.dbo.NashvilleHousing
  set SaleDateConverted = convert(date,SaleDate)

--------------------------------------------------------------------------------------------------

 /* 2. POPULATE PROPERTY ADDRESS
 Some of the records have Null value in the Property address.
 If the ParcelID is same, the null address is replaced with address from the other record having same Parcel_ID
 using SELF JOIN
 */

 --Check for null PropertyAddress
SELECT * from Portfolio.dbo.NashvilleHousing
where PropertyAddress is NULL
ORDER BY ParcelID

--Use Self Join 
SELECT a.uniqueID,a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress
from Portfolio.dbo.NashvilleHousing a
JOIN 
Portfolio.dbo.NashvilleHousing b
on a.ParcelID=b.ParcelID
and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is NULL
ORDER BY a.ParcelID

----Update the address
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from Portfolio.dbo.NashvilleHousing a
JOIN 
Portfolio.dbo.NashvilleHousing b
on a.ParcelID=b.ParcelID
and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is NULL

--------------------------------------------------------------------------------------------------------------------

/** 3.Segregate Address into Address and City in seperate Columns
The Property Address field has the address and City combined. 
It could be useful to separate the address and City in case we need to do some calculations based on the city.
Using the SUBSTRING to seperate the basis of the ',' in the String. 
The Property Address is split into 2 columns- Address_Split and City_Split
**/

Select PropertyAddress
from Portfolio.dbo.NashvilleHousing

select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address1,
 SUBSTRING (PropertyAddress , CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress) ) as City
from Portfolio.dbo.NashvilleHousing

-- Add 2 new columns to the table 
alter table Portfolio.dbo.NashvilleHousing
 add Address_Split varchar(255), City_Split varchar(255)

-- Update the 2 new columns by splitting
 Update Portfolio.dbo.NashvilleHousing
SET Address_Split = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ),
 City_Split = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

 select * from Portfolio.dbo.NashvilleHousing
---------------------------------------------------------------------------------------------------------------------


/**  4. CHECK FOR INCONSISTENCY
The Column SoldAsVacant has the issue of inconsistency as there are some records having 'Y' instead of 'Yes'
and 'N' instead of 'No'. This is checked using the Distict clause and grouped by SoldAsVacant  **/

select distinct(SoldAsVacant),count(SoldAsVacant)
from Portfolio.dbo.NashvilleHousing
group by SoldAsVacant
order by SoldAsVacant

-- Using the Case Statement change 'N' to 'No' and Y to 'Yes'. Update this to the table using UPDATE Command

select SoldAsVacant,
	case when SoldAsVacant= 'N' then 'No'
		 when SoldAsVacant= 'Y' then 'Yes'
		else SoldAsVacant
		end
from Portfolio.dbo.NashvilleHousing
order by SoldAsVacant

UPDATE Portfolio.dbo.NashvilleHousing
 SET SoldAsVacant  = case 
						when SoldAsVacant= 'N' then 'No'
				   	    when SoldAsVacant= 'Y' then 'Yes'
					    else SoldAsVacant
					end
------------------------------------------------------------------------------------------------------------

/**  4  REMOVE DUPLICATES  **/

with Row_N as(
SELECT * , 
ROW_NUMBER() OVER (Partition by ParcelID,   Address_Split,City_split, SalePrice, SaleDateConverted, LegalReference
				 ORDER BY
					UniqueID
					) row_n
from Portfolio.dbo.NashvilleHousing
)

delete 
from Row_N 
where row_n>1 
---------------------------------------------------------------------------------------------------------------------

/* DELETE UNUSED COLUMNS
The columns such as PropertyAddress,SaleDate which were modified and created new columns ,
hence can be deleted from the table using DROP function
*/

ALTER TABLE Portfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
---------------------------------------------------------------------------------------------------------------------


