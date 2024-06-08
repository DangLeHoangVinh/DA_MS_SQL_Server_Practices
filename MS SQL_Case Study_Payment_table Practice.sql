Select * from plans
Select * from subscriptions


-- tao bang sub2, subscription co plan end date ---------
drop table sub2;

SELECT *
       ,
       Case
       When Lead(start_date) over (partition by customer_id order by plan_id ASC) IS NULL
            Then (SELECT dateadd(day,1,MAX(start_date)) FROM subscriptions) -- ngay ket thuc la 01/05/2021
       Else Lead(start_date) over (partition by customer_id order by plan_id ASC)
       End as 'End_date' -- Plan end date _ lead time
into sub2
FROM subscriptions

select * from sub2;

---------- Create payment Table ------------------

--drop table payments;
Create table payments
(
     customer_id INT
     ,plan_id INT
     ,plan_name Varchar(20)
     ,payment_date DATE
     ,amount Decimal(5,2)
     , payment_order INT
)
-- 11
Declare @CusID INT = 1;
While (@CusID <= (Select Max(Customer_id) from sub2)) and (@CusID IN (Select Distinct Customer_id from sub2)) -- duyet tung Customer 1
begin
     Declare @PlanID INT = 0;
     Declare @Paytimes INT = 0;

     While @PlanID <= 4  -- duyet tung plan 1
     begin 
               Declare @PlanName Varchar(20) = 'N/A';
               Declare @Sdate Date;
               Declare @EDate Date;
               Declare @Amount DECIMAL(5,2);
--lay ra cac du lieu can thiet o moi plan ung voi customer id
          Select @PlanName = plan_name
               , @Sdate = Start_date
               , @Edate = End_date
               , @Amount = price
          from sub2 a
          join plans b
          on a.plan_id = b.plan_id
          Where a.customer_id = @CusID and a.plan_id = @PlanID
          if @Amount IS NULL begin Set @Amount = 0 End
--kiem tra khach hang co dang ky planid hien tai ko
      IF @PlanName <> 'N/A' -- PlanName <> N/A nghia la @CusID hien tai co dang ky @planID
          begin
               Declare @i int = 0;
--chen payment_date theo nam, moi nam dang ky lai 1 lan, planID = 3
               IF @PlanID = 3
               Begin
                    While dateadd(year,@i,@Sdate) <@EDate
                    begin
                         Set @Paytimes = @Paytimes + 1;
                         Insert into payments
                         (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
                         values
                         (@CusID, @PlanID,@PlanName,dateadd(month,@i,@Sdate), @Amount, @Paytimes)
                         Set @i= @i+1;
                    end
               end 
--Chen payment_date theo thang, moi thang dang ky lai 1 lan
               Else
               begin
                    While dateadd(month,@i,@Sdate) <@EDate
                    begin
-- danh dau khi khach hang thanh toan (plan 1,2,3)
                         If ((@PlanID <> 0) and (@PlanID <> 4)) begin set @Paytimes = @Paytimes + 1; end

                         Insert into payments
                         (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
                         values
                         (@CusID, @PlanID,@PlanName,dateadd(month,@i,@Sdate), @Amount, @Paytimes)
                         Set @i= @i+1;
                         if @PlanID = 4 begin break; end -- dung cap nhat khi khach hang huy dang ky
                    end
               End
          end
-- tang gia tri cua bien de tiep tuc vong lap
     Set @PlanID = @PlanID +1;
     end
     Set @CusID = @CusID + 1;
end

Select * from payments;

-- con bi loi id 16, payment update tu monthly basic to pro ko duoc tru tien (thieu promotion program)
