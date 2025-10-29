package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.DailyAggregates;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.*;

public interface DailyAggregatesRepository extends JpaRepository<DailyAggregates, Long> {
    Optional<DailyAggregates> findByUser_UserIdAndDate(Long userId, LocalDate date);

    @Query("""
      select da from DailyAggregates da
      where da.user.userId = :userId and da.date between :from and :to
      order by da.date desc
    """)
    List<DailyAggregates> findRange(@Param("userId") Long userId,
                                    @Param("from") LocalDate from,
                                    @Param("to") LocalDate to);
}
