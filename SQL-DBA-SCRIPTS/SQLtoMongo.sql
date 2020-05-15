--select count(*) from Customers
--select count(*) from Employees
--select count(*) from Products
--select count(*) from Sales
select SalesPersonID,CustomerID,ProductID,sum(quantity) from Sales
where SalesPersonID=23
group by SalesPersonID,CustomerID,ProductID

select * from Sales where SalesPersonID=23

select SalesPersonID,count(*) from Sales
group by SalesPersonID
order by count(*)

Select 
(Employees.FirstName+' '+Employees.LastName) as Sales_person,
(Customers.FirstName+' '+Customers.LastName) as Customer_name,
Products.[Name] as Product_name,
format(Products.Price,'C','te-IN') as Product_price,
sum(Sales.Quantity) as Quantity,
format((sum(Sales.Quantity)*Products.Price),'C','te-IN') as Total_price
from sales
inner join Employees
on Sales.SalesPersonID=Employees.EmployeeID
inner join Customers 
on  Sales.CustomerID=Customers.CustomerID
inner join Products
on Sales.ProductID=Products.ProductID
--where Sales.SalesPersonID=23
group by Products.[Name],Employees.FirstName,Employees.LastName,Products.Price,Customers.FirstName,Customers.LastName
--for json path
--for json auto--, root('sales_report')