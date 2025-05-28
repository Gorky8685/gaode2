package gaode;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * 每5分钟执行一次GetNav数据抓取的调度器
 */
public class SchedulerGetNav {
    public static void main(String[] args) {
        // 创建单线程的定时任务执行器
        ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

        // 定义需要定时执行的任务
        Runnable task = () -> {
            try {
                // 创建GetNav实例
                GetNav gdrun = new GetNav();
                // 使用runMul来进行多线程抓取（内部已包含links初始化）
                gdrun.runMul(gdrun);
                // 如果想用单线程方式执行，可将上行替换为：gdrun.runSingle();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        // 每隔5分钟执行一次任务：立即执行一次，然后每5分钟重复
        scheduler.scheduleAtFixedRate(task, 0, 5, TimeUnit.MINUTES);

        // 该程序将持续运行，每5分钟执行一次任务。如果您需要在某个条件下停止执行，
        // 可在适当时机调用 scheduler.shutdown()。
    }
}
